# -*- enconding : UTF-8 -*-
require 'spec_helper'
# Sidekiq::Testing.inline! #execute jobs immediatly

describe PreAssignment::AutoPreAssignedInvoicePieces do
  def allow_parameter
    allow_any_instance_of(TempPack).to receive(:not_processed?).and_return(true)
    allow(Reporting).to receive(:update).and_return(true)
    allow(FileDelivery).to receive(:prepare).and_return(true)
    allow_any_instance_of(Pack::Piece).to receive(:sign_piece).and_return(true)
  end

  def updating
    temp_document = @temp_pack.temp_documents.first
    temp_document.state = 'ready'
    temp_document.is_locked = false
    temp_document.save
  end

  def execute
    allow_parameter

    @temp_pack = @user.temp_packs.last
    updating

    DataProcessor::TempPack.execute(@temp_pack)

    @pack          = @user.packs.first
    @piece         = @pack.pieces.first
    @pieces        = @pack.pieces

    @preseizure    = Pack::Report::Preseizure.last
    @accounts      = Pack::Report::Preseizure::Account.limit(3).order("id DESC")
    @entries       = Pack::Report::Preseizure::Entry.limit(3).order("id DESC")
  end

  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2019,10,02))

    @user             = User.create(email: "commercial2@idocus.com", password: '123456', code: "ACC%IDO", first_name: "Service", last_name: "COMMERCIAL", phone_number: "0635407967", company: "iDocus")
    @user.create_options
    @user.create_notify
    @user.find_or_create_subscription

    @organization      = Organization.create(name: "ACCOMPLYS", description: "Organization accomplys", code: "ACC", subject_to_vat: true)

    @user.account_book_types.create(name: "VT", pseudonym: "", description: "(Ventes)", position: 1, entry_type: 2, currency: "EUR", domain: "VT - Ventes", account_number: "9DIV", default_account_number: "", charge_account: "471000", default_charge_account: "", vat_accounts: {'0':'445710', '20':'152451', '8.5':'153141', '13':'754213'}.to_json, anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: @organization.id)
    @user.organization = @organization
    @user.save

    @invoice           = Invoice.create(number: "2019090001", vat_ratio: 1.2, amount_in_cents_w_vat: 286277, content_file_name: "2019090001.pdf", organization_id: @organization.id, user_id: @user.id)
    @invoice.cloud_content.attach(Rack::Test::UploadedFile.new("#{Rails.root}/spec/support/files/2019090001.pdf"))
    @invoice.save
  end

  after(:all) do
    DatabaseCleaner.clean
    Timecop.return
  end


  context 'DataProcessor::TempPack' do
    before(:each) do
      TempDocument.destroy_all
      TempPack.destroy_all
      Pack::Piece.destroy_all

      create_invoice_pdf = Billing::CreateInvoicePdf.new(@invoice)
      create_invoice_pdf.auto_upload_last_invoice

      @temp_pack = @user.temp_packs.last
    end

    it '@temp_pack.not_processed_count should 0 and @temp_document.api_name should be invoice_auto' do
      expect(@temp_pack.not_processed_count).to eq(0)
      expect(Pack::Piece.count).to eq(0)
      expect(@temp_pack.temp_documents.first.api_name).to eq 'invoice_auto'
    end

    it '@temp_pack.not_processed_count should 0 and @temp_document.api_name should be invoice_auto' do
      allow_parameter

      updating

      DataProcessor::TempPack.execute(@temp_pack)

      @temp_pack.reload

      expect(@temp_pack.not_processed_count).to eq(0)
      expect(@temp_pack.temp_documents.first.api_name).to eq 'invoice_auto'
      expect(Pack::Piece.count).to eq(1)
    end

    it 'should only call AutoPreAssignedInvoicePieces.execute(@pieces) method when invoice_piece is not empty' do
      allow_parameter

      expect(AccountingWorkflow::SendPieceToPreAssignment).to_not receive(:execute)
      expect(PreAssignment::AutoPreAssignedInvoicePieces).to receive(:execute).exactly(:once)

      updating

      DataProcessor::TempPack.execute(@temp_pack)
    end

    it 'should not call AutoPreAssignedInvoicePieces.execute(@pieces) method when invoice_piece is empty' do
      allow_parameter

      temp_document = TempDocument.first
      temp_document.api_name = 'upload'
      temp_document.save

      expect(AccountingWorkflow::SendPieceToPreAssignment).to_not receive(:execute)
      expect(PreAssignment::AutoPreAssignedInvoicePieces).to receive(:execute).exactly(0).times

      DataProcessor::TempPack.process(@temp_pack.name)
    end
  end

  context 'AutoPreAssignedInvoicePieces.new(@piece).execute' do
    before(:each) do
      TempDocument.destroy_all
      TempPack.destroy_all
      Pack::Piece.destroy_all
      Pack::Report::Preseizure.destroy_all
      Pack::Report::Preseizure::Account.destroy_all
      Pack::Report::Preseizure::Entry.destroy_all

      create_invoice_pdf = Billing::CreateInvoicePdf.new(@invoice)
      create_invoice_pdf.auto_upload_last_invoice
    end

    it 'returns a valid preseizure datas', :preseizure_data do
      execute
      
      @preseizure.reload

      expect(@preseizure.piece).to eq @piece
      expect(@preseizure.date.to_date).to eq "Mon, 30 Sep 2019".to_date
      expect(@preseizure.deadline_date.to_date).to eq "Fri, 04 Oct 2019".to_date
      expect(@preseizure.report.name).to eq 'ACC%IDO VT 201909'
      expect(@preseizure.piece_number).to eq @invoice.number
      expect(@preseizure.position).to eq @piece.position
      expect(@preseizure.organization).to eq @organization
      expect(@preseizure.cached_amount).to eq @preseizure.entries.map(&:amount).max
      expect(@preseizure.third_party).to eq(@invoice.organization.addresses.for_billing.first.try(:company)).or eq(@invoice.organization.name)
    end

    it 'returns a valid account numbers' do
      execute

      expect(@accounts[0].type).to eq (3)
      expect(@accounts[0].number).to eq('445710')

      expect(@accounts[1].type).to eq (2)
      expect(@accounts[1].number).to eq('706000')

      expect(@accounts[2].type).to eq (1)
      expect(@accounts[2].number).to eq('9DIV')
    end

    it 'returns a valid entries numbers and amounts' do
      execute

      expect(@entries[0].type).to eq(2)
      expect(@entries[0].number).to eq '0'
      expect(sprintf("%.2f", @entries[0].amount).to_f).to eq (477.13)

      expect(@entries[1].type).to eq(2)
      expect(@entries[1].number).to eq '0'
      expect(sprintf("%.2f", @entries[1].amount).to_f).to eq (2385.64)

      expect(@entries[2].type).to eq(1)
      expect(@entries[2].number).to eq '0'
      expect(sprintf("%.2f", @entries[2].amount).to_f).to eq (2862.77)
    end

    context 'Logs' do
      before(:each) do
        @log_file = "#{Rails.root}/log/#{Rails.env}_auto_upload_invoice.log"
        File.unlink(@log_file) if File.exist? @log_file
      end

      it 'returns success when preseizure is saved and persisted' do
        execute
        PreAssignment::AutoPreAssignedInvoicePieces.execute(@pieces)

        log_content = File.read(@log_file)

        expect(File.exist?(@log_file)).to be true
        expect(log_content).to match /preseizure persisted/i
      end

      it 'returns errors when preseizure is not saved' do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:save).and_return(false)
        execute

        auto_pre_assigned_invoice_piece = PreAssignment::AutoPreAssignedInvoicePieces.new(@piece)
        auto_pre_assigned_invoice_piece.execute

        log_content = File.read(@log_file)

        expect(File.exist?(@log_file)).to be true
        expect(log_content).to match /errors :/i
      end
    end
  end
end