# -*- encoding : UTF-8 -*-
class RetrievedData < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => ''}

  belongs_to :user

  serialize :processed_connection_ids, Array

  has_one_attached :cloud_content

  has_attached_file :content, path: ':rails_root/files/:rails_env/:class/content/:id/:filename'
  do_not_validate_attachment_file_type :content

  scope :processed,     -> { where(state: 'processed') }
  scope :not_processed, -> { where(state: 'not_processed') }
  scope :error,         -> { where(state: 'error') }

  before_destroy do |retrieved_data|
    retrieved_data.cloud_content.purge
  end

  state_machine initial: :not_processed do
    state :not_processed
    state :processed
    state :error

    event :processed do
      transition :not_processed => :processed
    end

    event :error do
      transition :not_processed => :error
    end

    event :continue do
      transition :error => :not_processed
    end
  end

  def self.remove_oldest
    RetrievedData.where('created_at < ?', 1.month.ago).destroy_all
  end

  def json_content=(data)
    # self.content = StringIO.new(SymmetricEncryption.encrypt(Oj.dump(data)))
    # self.content_file_name = 'data.blob'
    self.cloud_content.attach(io: StringIO.new(SymmetricEncryption.encrypt(Oj.dump(data))), filename: 'data.blob')
  end

  def json_content
    Oj.load(SymmetricEncryption.decrypt(File.read(cloud_content_object.path)))
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end
end
