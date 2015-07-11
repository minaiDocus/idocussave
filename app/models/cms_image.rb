# -*- encoding : UTF-8 -*-
class CmsImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :original_file_name

  has_mongoid_attached_file :content,
    styles: {
      thumb: ["96x96>", :png],
    },
    path: ":rails_root/public:url",
    url: "/system/:rails_env/:class/:attachment/:id/:style/:filename"
  do_not_validate_attachment_file_type :content

  def self.find_by_name(name)
    any_of({ original_file_name: name }, { content_file_name: name }).first
  end

  def name
    self.original_file_name || content_file_name
  end
end
