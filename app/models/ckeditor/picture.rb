class Ckeditor::Picture < Ckeditor::Asset
  ATTACHMENTS_URLS={'cloud_data' => '/ckeditor_assets/pictures/:id/:style_:basename.:extension'}

  has_one_attached :cloud_data
  
  has_attached_file :data,
                    url: '/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    path: ':rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    styles: { content: '800>', thumb: '118x100#' }

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 2.megabytes
  validates_attachment_content_type :data, content_type: /\Aimage/

  before_destroy do |document|
    document.cloud_data.purge
  end

  def cloud_data_object
    CustomActiveStorageObject.new(self, :cloud_data)
  end

  def url_content
    url(:content)
  end
end
