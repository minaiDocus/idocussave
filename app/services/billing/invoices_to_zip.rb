# -*- encoding : UTF-8 -*-
# Creates a Zip archive with instanciated invoices
class Billing::InvoicesToZip
  def initialize(invoice_ids)
    @invoice_ids = invoice_ids
  end


  def execute
    zip_path = ''

    CustomUtils.mktmpdir('invoice_to_zip', nil, false) do |dir|
      Billing::InvoicesToZip.delay_for(6.hours).remove_temp_dir(dir)

      @invoice_ids.each do |invoice_id|
        invoice = Invoice.find invoice_id
        filepath = invoice.cloud_content_object.path

        next unless File.exist?(filepath)

        if invoice.organization
          filename = invoice.organization.name + ' - ' + invoice.period.start_date.strftime('%Y%m') + '.pdf'
        elsif invoice.user
          filename =  invoice.user.code + ' - ' + invoice.period.start_date.strftime('%Y%m') + '.pdf'
        else
          filename = File.basename(filepath)
        end

        new_filepath = File.join dir, filename

        FileUtils.cp(filepath, new_filepath)
      end

      zip_path = File.join(dir, 'factures.zip')

      system "zip -j #{zip_path} #{dir}/*"
    end

    zip_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.rm_rf dir if File.exist? dir
  end
end
