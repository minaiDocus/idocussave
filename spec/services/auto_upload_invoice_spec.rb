# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe CreateInvoicePdf do
  context 'auto_upload_last_invoice' do
    before(:all) do
      DatabaseCleaner.start
			@user = User.create(email: "commercial2@idocus.com", password: '123456', code: "ACC%IDO", first_name: "Service", last_name: "COMMERCIAL", phone_number: "0635407967", company: "iDocus")
			@organization = create :organization

			@user.account_book_types.create(name: "VT", pseudonym: "", description: "(Ventes)", position: 1, entry_type: 2, currency: "EUR", domain: "VT - Ventes", account_number: "0ACC", default_account_number: "", charge_account: "471000", default_charge_account: "", vat_account: "445660", vat_account_10: nil, vat_account_8_5: nil, vat_account_5_5: nil, vat_account_2_1: nil, anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, instructions: "Regroupez dans cette chemise :\r\nLes factures payée...", organization_id: @organization.id)
			@user.organization = @organization
			@user.save

	  	@invoice = Invoice.create(number: "2019090001", organization_id: @organization.id, user_id: @user.id)
      @invoice.cloud_content.attach(Rack::Test::UploadedFile.new("#{Rails.root}/spec/support/files/2019090001.pdf"))
      @invoice.save
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    context 'temp_document need Timecop' do
    	before(:each) do
    		Timecop.freeze(Time.local(2020,04,1))
	    end

	    after(:each) do
	      Timecop.return
	    end

	    it 'archive invoice', :archive_invoice do
		  	CreateInvoicePdf.archive_invoice

		  	archive_invoice = ArchiveInvoice.last

		  	expect(archive_invoice.name).to eq 'invoices_202003.zip'
		  	expect(archive_invoice.cloud_content).to be_attached
	      expect(archive_invoice.cloud_content_object.path).to be_present
	      expect(archive_invoice.cloud_content_object.path).to match /ArchiveInvoice\/20200401\/1\/invoices_202003\.zip/
	      expect(archive_invoice.cloud_content.filename).to eq 'invoices_202003.zip'
	  	end

    	it 'returns a valid temp document', :temp_doc_created do
		  	create_invoice_pdf = CreateInvoicePdf.new(@invoice)
		  	create_invoice_pdf.auto_upload_last_invoice

		  	temp_document = TempDocument.last

		  	expect(temp_document.delivered_by).to eq 'ACC%IDO'
		  	expect(temp_document.delivery_type).to eq 'upload'
		  	expect(temp_document.api_name).to eq 'invoice_auto'

		   	expect(temp_document.original_file_name).to eq '2019090001.pdf'
		   	expect(temp_document.content_file_name).to  eq 'ACC%IDO_VT_202003'
		    expect(temp_document.state).to  eq 'ready'
	  	end

	  	context 'Test success and error' do
	  		before(:each) do
	  			@log_file = "#{Rails.root}/log/#{Rails.env}_auto_upload_invoice.log"
		  		File.unlink(@log_file) if File.exist? @log_file
	  		end

		  	it 'returns a log state "upladed"', :log_success do
		  		allow_any_instance_of(UploadedDocument).to receive(:valid?).and_return(true)
		  		
		  		create_invoice_pdf = CreateInvoicePdf.new(@invoice)
		  		create_invoice_pdf.auto_upload_last_invoice

		  		log_content = File.read(@log_file)

		  		expect(File.exist?(@log_file)).to be true
		  		expect(log_content).to match /Uploaded/
		  	end

		  	it 'returns a log state "with error"', :log_error do
		  		allow_any_instance_of(UploadedDocument).to receive(:valid?).and_return(false)
		  		allow_any_instance_of(UploadedDocument).to receive(:full_error_messages).and_return('journal error')

		  		create_invoice_pdf = CreateInvoicePdf.new(@invoice)
		  		create_invoice_pdf.auto_upload_last_invoice

					log_content = File.read(@log_file)
					
					expect(File.exist?(@log_file)).to be true
		  		expect(log_content).to match /journal error/
		  	end

		  	it 'returns a log state "already exist"', :log_error_v2 do
		  		create_invoice_pdf = CreateInvoicePdf.new(@invoice)
		  		create_invoice_pdf.auto_upload_last_invoice
		  		create_invoice_pdf.auto_upload_last_invoice
				
					log_content = File.read(@log_file)

					expect(File.exist?(@log_file)).to be true
		  		expect(log_content).to match /existe déjà/
		  	end
		  end
    end
  end
end