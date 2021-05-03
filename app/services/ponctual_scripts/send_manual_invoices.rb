class PonctualScripts::SendManualInvoices < PonctualScripts::PonctualScript
  def self.execute(with_email=true)
    new({with_email: with_email}).run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    _time = Time.now.to_date.beginning_of_month

    lock_with("manual_invoices_sending#{_time.strftime('%Y%m')}.txt") do |file_name|
      begin
        user = User.find_by_code 'ACC%IDO' # Always send invoice to ACC%IDO customer

        Organization.billed.each do |organization|
          invoice = organization.invoices.where("DATE_FORMAT(created_at, '%Y%m') = '#{_time.strftime('%Y%m')}'").last

          next if not invoice

          file = File.new invoice.cloud_content_object.reload.path
          content_file_name = invoice.cloud_content_object.filename

          uploaded_document = UploadedDocument.new( file, content_file_name, user, 'VT', 1, nil, 'invoice_auto', nil )

          logger_infos "[SendManualInvoices] - Customer: ACC%IDOC-VT / state: #{uploaded_document.full_error_messages}"

          if(@options[:with_email])
            organization.admins.each do |admin|
              Notifications::Notifier.new.create_notification({
                url: Rails.application.routes.url_helpers.account_profile_url({ panel: 'invoices' }.merge(ActionMailer::Base.default_url_options)),
                user: admin,
                notice_type: 'invoice',
                title: "Nouvelle facture disponible",
                message: "Votre facture pour le mois de #{I18n.l(invoice.period.start_date, format: '%B')} est maintenant disponible."
              }, false)
            end

            InvoiceMailer.delay(queue: :high).notify(invoice)
            logger_infos "[SendManualInvoices] - Organization: #{organization.code} / sending email: true"
          end

          auto_upload_invoice_setting(organization, file, content_file_name)
        end
      rescue => e
        logger_infos "[SendManualInvoices] - Customer: ACC%IDOC-VT / state: #{e.to_s}"
      end
    end
  end

  def backup; end

  def auto_upload_invoice_setting(organization, file, content_file_name)
    invoice_settings = organization.invoice_settings || []

    invoice_settings.each do |invoice_setting|
      next unless invoice_setting.user.try(:options).try(:is_upload_authorized)

      uploaded_document = UploadedDocument.new( file, content_file_name, invoice_setting.user, invoice_setting.journal_code, 1, nil, 'invoice_setting', nil )
      logger_infos "[SendManualInvoices] - Customer: #{invoice_setting.user.code}-#{invoice_setting.journal_code} / state: #{uploaded_document.full_error_messages}"
    end
  end
end
