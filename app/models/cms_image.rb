# -*- encoding : UTF-8 -*-
class CmsImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :content_file_name
  field :content_file_type
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time

  has_mongoid_attached_file :content,
    styles: {
      thumb: ["96x96>", :png],
    },
    path: ":rails_root/public:url",
    url: "/system#{Rails.env.test? ? '_test' : ''}/:attachment/:id/:style/:filename"

  def self.find_by_name(name)
    self.first conditions: { content_file_name: name }
  end
end
