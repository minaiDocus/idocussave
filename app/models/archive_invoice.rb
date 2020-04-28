class ArchiveInvoice < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/archives/invoices/'}

  has_one_attached :cloud_content

  validates_presence_of   :name
  validates_uniqueness_of :name

  before_destroy do |archive_invoice|
    archive_invoice.cloud_content.purge
  end
 
  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def self.archive(time = Time.now)
    invoices   = Invoice.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month)
    file_path  = archive_path archive_name(time - 1.month)
    files_path = invoices.map { |e| e.cloud_content_object.path }

    DocumentTools.archive(file_path, files_path)
  end

  def self.archive_name(time = Time.now)
    "invoices_#{time.strftime('%Y%m')}.zip"
  end

  def self.archive_path(file_name)
    archive_invoice = ArchiveInvoice.where(name: file_name).first
    if archive_invoice.present? && File.exist?(archive_invoice.cloud_content_object.path.to_s)
      archive_invoice.cloud_content_object.try(:path)
    else
      _file_name = File.basename file_name

      File.join Rails.root, 'files', Rails.env, 'archives', 'invoices', _file_name
    end
  end
end
