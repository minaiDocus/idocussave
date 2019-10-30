# -*- enconding : UTF-8 -*-
require 'spec_helper'

describe AutoPreAssignedInvoicePieces do
	before(:all) do
		DatabaseCleaner.start
    Timecop.freeze(Time.local(2019,10,02))

    @user             = User.create(email: "commercial2@idocus.com", password: '123456', code: "ACC%IDO", first_name: "Service", last_name: "COMMERCIAL", phone_number: "0635407967", company: "iDocus")
    @user.create_options
    @user.create_notify
    @user.find_or_create_subscription

    @organization      = Organization.create(name: "ACCOMPLYS", description: "Organization accomplys", code: "ACC", subject_to_vat: true)

		@user.account_book_types.create(name: "VT", pseudonym: "", description: "(Ventes)", position: 1, entry_type: 2, currency: "EUR", domain: "VT - Ventes", account_number: "9DIV", default_account_number: "", charge_account: "471000", default_charge_account: "", vat_account: "445710", anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: @organization.id)
		@user.organization = @organization
		@user.save

  	@invoice           = Invoice.create(number: "2019090001", vat_ratio: 1.2, amount_in_cents_w_vat: 2862.77, content_file_name: "2019090001.pdf", organization_id: @organization.id, user_id: @user.id)
  	@invoice.content   = File.new "#{Rails.root}/spec/support/files/2019090001.pdf"
    @invoice.save
  end

  after(:all) do
    DatabaseCleaner.clean
    Timecop.return
	end


  context 'AccountingWorkflow::TempPackProcessor' do
    before(:each) do
      TempDocument.destroy_all
      TempPack.destroy_all
      Pack::Piece.destroy_all

      create_invoice_pdf = CreateInvoicePdf.new(@invoice)
      create_invoice_pdf.auto_upload_last_invoice

      @temp_pack = @user.temp_packs.last
    end

    it '@temp_pack.document_not_processed_count should 0 and @temp_document.api_name should be invoice_auto' do
      expect(@temp_pack.document_not_processed_count).to eq(1)
      expect(Pack::Piece.count).to eq(0)
      expect(@temp_pack.temp_documents.first.api_name).to eq 'invoice_auto'
    end

    it '@temp_pack.document_not_processed_count should 0 and @temp_document.api_name should be invoice_auto' do
      AccountingWorkflow::TempPackProcessor.process(@temp_pack)

      @temp_pack.reload

      expect(@temp_pack.document_not_processed_count).to eq(0)
      expect(@temp_pack.temp_documents.first.api_name).to eq 'invoice_auto'
      expect(Pack::Piece.count).to eq(1)
    end

    it 'should only call AutoPreAssignedInvoicePieces.execute(@pieces) method when invoice_piece is not empty' do
      expect(AccountingWorkflow::SendPieceToPreAssignment).to_not receive(:execute).exactly(0).times
      expect(AutoPreAssignedInvoicePieces).to receive(:execute).exactly(:once)

      AccountingWorkflow::TempPackProcessor.process(@temp_pack)
    end

    it 'should not call AutoPreAssignedInvoicePieces.execute(@pieces) method when invoice_piece is empty' do
      temp_document = TempDocument.first
      temp_document.api_name = 'upload'
      temp_document.save

      expect(AccountingWorkflow::SendPieceToPreAssignment).to_not receive(:execute).exactly(1).times
      expect(AutoPreAssignedInvoicePieces).to receive(:execute).exactly(0).times

      AccountingWorkflow::TempPackProcessor.process(@temp_pack)
    end
  end

  context 'AutoPreAssignedInvoicePieces.new(@piece).execute' do
    before(:all) do
      TempDocument.destroy_all
      TempPack.destroy_all
      Pack::Piece.destroy_all
      Pack::Report::Preseizure.destroy_all
      Pack::Report::Preseizure::Account.destroy_all
      Pack::Report::Preseizure::Entry.destroy_all

      create_invoice_pdf = CreateInvoicePdf.new(@invoice)
      create_invoice_pdf.auto_upload_last_invoice

      @temp_pack = @user.temp_packs.last

      AccountingWorkflow::TempPackProcessor.process(@temp_pack)

      @pack          = @user.packs.first
      @piece         = @pack.pieces.first
      @pieces        = @pack.pieces

      @preseizure    = Pack::Report::Preseizure.last
      @accounts      = Pack::Report::Preseizure::Account.limit(3).order("id DESC")
      @entries       = Pack::Report::Preseizure::Entry.limit(3).order("id DESC")
    end

  	it 'returns a valid preseizure datas', :preseizure_data do
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
      expect(@accounts[0].type).to eq (3)
      expect(@accounts[0].number).to eq('445710')

      expect(@accounts[1].type).to eq (2)
      expect(@accounts[1].number).to eq('706000')

      expect(@accounts[2].type).to eq (1)
      expect(@accounts[2].number).to eq('9DIV')
		end

		it 'returns a valid entries numbers and amounts' do
      expect(@entries[0].type).to eq(2)
      expect(@entries[0].number).to eq '0'
      expect(sprintf("%.2f", @entries[0].amount).to_f).to eq (477.0)

      expect(@entries[1].type).to eq(2)
      expect(@entries[1].number).to eq '0'
      expect(sprintf("%.2f", @entries[1].amount).to_f).to eq (2385.0)

		  expect(@entries[2].type).to eq(1)
		  expect(@entries[2].number).to eq '0'
      expect(sprintf("%.2f", @entries[2].amount).to_f).to eq (2862.0)
		end

  	context 'Logs' do
  		before(:each) do
  			@log_file = "#{Rails.root}/log/#{Rails.env}_auto_upload_invoice.log"
	  		File.unlink(@log_file) if File.exist? @log_file
  		end

  		it 'returns success when preseizure is saved and persisted' do
	  		AutoPreAssignedInvoicePieces.execute(@pieces)

	  		log_content = File.read(@log_file)

	  		expect(File.exist?(@log_file)).to be true
	  		expect(log_content).to match /preseizure persisted/i
	  	end

	  	it 'returns errors when preseizure is not saved' do
	  		allow_any_instance_of(Pack::Report::Preseizure).to receive(:save).and_return(false)

	  		auto_pre_assigned_invoice_piece = AutoPreAssignedInvoicePieces.new(@piece)
	  		auto_pre_assigned_invoice_piece.execute

	  		log_content = File.read(@log_file)

	  		expect(File.exist?(@log_file)).to be true
	  		expect(log_content).to match /errors :/i
	  	end

	  	it 'returns airbrake notification' do
	  		allow_any_instance_of(Invoice).to receive(:present?).and_raise('error')

	  		expect(Airbrake).to receive(:notify).once

	  		auto_pre_assigned_invoice_piece = AutoPreAssignedInvoicePieces.new(@piece)
	  		auto_pre_assigned_invoice_piece.execute
	  	end
	  end
  end
end