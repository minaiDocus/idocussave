# -*- encoding : UTF-8 -*-
class InvoicesToZip
  def initialize(invoice_ids)
    @invoice_ids = invoice_ids
  end

  def execute
    dir = Dir.mktmpdir
    InvoicesToZip.remove_temp_dir(dir)
    @invoice_ids.each do |invoice_id|
      invoice = Invoice.find invoice_id
      filepath = invoice.content.path

      if File.exist?(filepath)
        if invoice.organization
          filename = invoice.organization.name + ' - ' + invoice.period.start_at.strftime("%Y%m") + '.pdf'
        elsif invoice.user
          filename =  invoice.user.code + ' - ' + invoice.period.start_at.strftime("%Y%m") + '.pdf'
        else
          filename = File.basename(filepath)
        end
        new_filepath = File.join dir, filename
        FileUtils.cp(filepath, new_filepath)
      end
    end
    zip_path =  File.join(dir, 'factures.zip')
    system "zip -j #{zip_path} #{dir}/*"
    zip_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.rm_rf dir if File.exist? dir
    end
    handle_asynchronously :remove_temp_dir, :run_at => Proc.new { 1.hour.from_now }
  end
end
