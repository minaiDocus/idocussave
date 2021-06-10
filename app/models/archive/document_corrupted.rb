# -*- encoding : UTF-8 -*-
class Archive::DocumentCorrupted < ApplicationRecord
  self.table_name = 'archive_document_corrupted'

  ATTACHMENTS_URLS={'cloud_content' => ''}

  serialize :params, Hash

  belongs_to :user, optional: true

  has_one_attached :cloud_content

  scope :retryable, -> { where('retry_count < 2') }
  scope :old_documents, -> { where('created_at < ? ', 6.month.ago) }
  scope :to_notify, -> { where('retry_count > ? AND is_notify = ? ', 1, false) }

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end
end