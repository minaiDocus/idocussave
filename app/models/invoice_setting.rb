class InvoiceSetting < ApplicationRecord
  validates_presence_of   :user_code, :journal_code

  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :invoice, optional: true

  def self.invoice_synchronize(period, invoice_setting_id)
    invoice_setting = InvoiceSetting.find(invoice_setting_id)

    invoices_to_synchronize = Invoice.where('created_at >= ? AND created_at <= ? AND organization_id = ?', period, Time.now, invoice_setting.organization.id)

    invoices_to_synchronize.each do |invoice_to_synchonize|
      @invoice = invoice_to_synchonize
      filename = @invoice.cloud_content_object.filename
      file = File.open(@invoice.cloud_content_object.path)
      uploaded_document = UploadedDocument.new( file, filename, invoice_setting.user, invoice_setting.journal_code, 0, nil, 'invoice_setting', nil )

      logger_message_content(uploaded_document)
    end
  end

  def self.logger_message_content(uploaded_document)
    if uploaded_document.valid?
      System::Log.info('auto_upload_invoice_setting_synchronize', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Uploaded")
    else
      System::Log.info('auto_upload_invoice_setting_synchronize', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - #{uploaded_document.full_error_messages}")
    end
  end

end
