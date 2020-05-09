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

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def content
    object = FakeObject.new
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

      File.join Rails.root, 'files', 'archives', 'invoices', _file_name
    end
  end
end
