class Ckeditor::AttachmentFile < Ckeditor::Asset
  ATTACHMENTS_URLS={'cloud_data' => '/ckeditor_assets/attachments/:id/:filename'}

  has_one_attached :cloud_data

  has_attached_file :data,
                    url: '/ckeditor_assets/attachments/:id/:filename',
                    path: ':rails_root/public/ckeditor_assets/attachments/:id/:filename'

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 100.megabytes
  do_not_validate_attachment_file_type :data

  before_destroy do |document|
    document.cloud_data.purge
  end

  def cloud_data_object
    CustomActiveStorageObject.new(self, :cloud_data)
  end

  def url_thumb
    @url_thumb ||= Ckeditor::Utils.filethumb(filename)
  end
end
