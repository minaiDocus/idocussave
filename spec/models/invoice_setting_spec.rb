require 'spec_helper'

describe InvoiceSetting do
  before(:each) do
    DatabaseCleaner.start

    users = [
        { email: "acc007@idocus.com", password: '123456', code: "AC0077", first_name: "AC0077 test", last_name: "AC0077 test", phone_number: "123", company: "Accomplys" },
        { email: "acc0239@idocus.com", password: '654321', code: "ACC%0239", first_name: "ACC%0239 test", last_name: "ACC%0239 test", phone_number: "123", company: "Accomplys" }
      ]

      users.map {|user| User.new(user).save }

      _users = User.limit(2)

      @user = User.create(email: "commercial2@idocus.com", password: '123456', code: "ACC%IDO", first_name: "Service", last_name: "COMMERCIAL", phone_number: "0635407967", company: "iDocus")
      @organization = create :organization

      _users.each do |user|
        user.account_book_types.create(name: "AC", description: "AC (Achats)", position: 1, entry_type: 2, currency: "EUR", domain: "AC - Achats", account_number: "0ACC", charge_account: "471000", vat_accounts: "{'20':'445660', '8.5':'153141', '13':'754213'}", anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, organization_id: @organization.id)
        user.organization = @organization
        user.save
      end

      @user.account_book_types.create(name: "VT", pseudonym: "", description: "VT (Ventes)", position: 1, entry_type: 2, currency: "EUR", domain: "VT - Ventes", account_number: "0ACC", default_account_number: "", charge_account: "471000", default_charge_account: "", vat_accounts: "{'20':'445660', '8.5':'153141', '13':'754213'}", anomaly_account: "471000", is_default: true, is_expense_categories_editable: true, instructions: "Regroupez dans cette chemise :\r\nLes factures payée...", organization_id: @organization.id)
      @user.organization = @organization
      @user.save

      #@invoice_setting = InvoiceSetting.create(organization_id: @organization.id, user_id: @user.id, user_code: "ACC%IDO", journal_code: "VT")

      invoice_settings = [
        { organization_id: @organization.id, user_id: _users[0].id, user_code: "AC0077", journal_code: "AC" },
        { organization_id: @organization.id, user_id: _users[1].id, user_code: "ACC%0239", journal_code: "AC" }
      ]

      invoice_settings.map {|invoice_setting| InvoiceSetting.new(invoice_setting).save }

      @invoice = Invoice.create(number: "2019090001", organization_id: @organization.id, user_id: @user.id)

      @invoice.cloud_content_object.attach(File.open("#{Rails.root}/spec/support/files/2019090001.pdf"), '2019090001.pdf')
      @invoice.save
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'synchronize invoice setting', :invoice_synchronize do
    before(:each) do
      @log_file = "#{Rails.root}/log/#{Rails.env}_auto_upload_invoice_setting_synchronize.log"
      File.unlink(@log_file) if File.exist? @log_file
    end

    it 'returns a log state "uploaded"', :log_success do
      allow_any_instance_of(UploadedDocument).to receive(:valid?).and_return(true)

      invoice_setting = InvoiceSetting.last
      period = 1.month.ago

      InvoiceSetting.invoice_synchronize(period, invoice_setting.id)

      log_content = File.read(@log_file)

      expect(File.exist?(@log_file)).to be true
      expect(log_content).to match /Uploaded/
    end

    it 'returns a log state "with error"', :log_error do
      allow_any_instance_of(UploadedDocument).to receive(:valid?).and_return(false)
      allow_any_instance_of(UploadedDocument).to receive(:full_error_messages).and_return('journal error')

      invoice_setting = InvoiceSetting.last
      period = 1.month.ago

      InvoiceSetting.invoice_synchronize(period, invoice_setting.id)

      log_content = File.read(@log_file)

      expect(File.exist?(@log_file)).to be true
      expect(log_content).to match /journal error/
    end

    it 'returns a log state "already exist"', :log_error_v2 do
      invoice_setting = InvoiceSetting.last
      period = 1.month.ago

      InvoiceSetting.invoice_synchronize(period, invoice_setting.id)
      InvoiceSetting.invoice_synchronize(period, invoice_setting.id)

      log_content = File.read(@log_file)

      expect(TempDocument.count).to eq 1
      expect(TempDocument.last.api_name).to eq 'invoice_setting'
      expect(File.exist?(@log_file)).to be true
      expect(log_content).to match /existe déjà/
    end
  end
end