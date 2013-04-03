# -*- encoding : UTF-8 -*-
class CmsImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :original_file_name
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
    any_of({ original_file_name: name }, { content_file_name: name }).first
  end

  def name
    self.original_file_name || content_file_name
  end
end
