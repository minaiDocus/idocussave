# -*- encoding : UTF-8 -*-
class Archive::DocumentCorrupted < ApplicationRecord
  self.table_name = 'archive_document_corrupted'

  ATTACHMENTS_URLS={'cloud_content' => ''}

  serialize :params, Hash

  belongs_to :user, optional: true

  has_one_attached :cloud_content

  scope :retryable, -> { where('state = ? AND retry_count < ?', 'ready', 2) }
  scope :old_documents, -> { where('created_at < ? ', 6.month.ago) }
  scope :to_notify, -> { where('state = ? AND is_notify = ? ', 'rejected', false) }

  state_machine initial: :ready do
    state :ready
    state :uploaded
    state :rejected

    event :ready do
      transition any: :ready
    end

    event :uploaded do
      transition ready: :uploaded
    end

    event :rejected do
      transition ready: :rejected
    end
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end
end