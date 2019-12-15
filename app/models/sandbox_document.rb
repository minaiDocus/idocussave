# -*- encoding : UTF-8 -*-
class SandboxDocument < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :retriever, optional: true

  serialize :retrieved_metadata, Hash

  has_one_attached :cloud_content

  has_attached_file :content, path: ":rails_root/files/:rails_env/:class/:id/:filename"
  do_not_validate_attachment_file_type :content
end
