# -*- encoding : UTF-8 -*-
class SandboxDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :api_id
  field :api_name, default: 'budgea'
  field :retrieved_metadata, type: Hash

  index({ api_id: 1 })
  index({ api_name: 1 })

  belongs_to :user,      index: true
  belongs_to :retriever, index: true
  has_mongoid_attached_file :content, path: ":rails_root/files/:rails_env/:class/:id/:filename"
  do_not_validate_attachment_file_type :content
end
