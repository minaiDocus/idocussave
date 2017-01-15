# -*- encoding : UTF-8 -*-
class SandboxDocument < ActiveRecord::Base
  belongs_to :user
  belongs_to :retriever

  serialize :retrieved_metadata, Hash

  has_attached_file :content, path: ":rails_root/files/:rails_env/:class/:id/:filename"
  do_not_validate_attachment_file_type :content
end
