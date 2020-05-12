# -*- encoding : UTF-8 -*-
class CmsImage < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => ''}
  has_one_attached :cloud_content
  has_one_attached :cloud_content_thumbnail
  
  has_attached_file :content,
                            styles: {
                              thumb: ['96x96>', :png]
                            },
                            path: ':rails_root/public:url',
                            url: '/system/:rails_env/:class/:attachment/:id/:style/:filename',
                            use_timestamp: false
  do_not_validate_attachment_file_type :content

  before_destroy do |cms_image|
    cms_image.cloud_content.purge
    cms_image.cloud_content_thumbnail.purge
  end

  after_create_commit do |cms_image|
      cms_image.generate_thumbs
  end

  def self.get_path_of(identity)
    _id = identity.gsub('cms_image:', '')

    begin
      cms_image = CmsImage.find _id.to_i
      cms_image.cloud_content_object.path
    rescue
      ''
    end
  end

  def generate_thumbs
    begin
      image = MiniMagick::Image.read(self.cloud_content.download).format('png').resize('92x133')

      self.cloud_content_thumbnail.attach(io: File.open(image.tempfile), 
                                         filename: "#{self.id}_thumb.png", 
                                         content_type: "image/png")
    rescue
    end
  end

  def get_identity
    "cms_image:#{self.id}"
  end

  def name
    original_file_name || content_file_name
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def content_thumbnail
    object = FakeObject.new
  end

  def cloud_content_thumbnail_object
    CustomActiveStorageObject.new(self, :cloud_content_thumbnail)
  end
end
