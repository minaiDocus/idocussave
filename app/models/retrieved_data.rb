# -*- encoding : UTF-8 -*-
class RetrievedData < ActiveRecord::Base
  belongs_to :user

  serialize :processed_connection_ids, Array

  has_attached_file :content, path: ':rails_root/:new_or_old_retrieved_data_folder/:rails_env/:class/content/:id/:filename'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :new_or_old_retrieved_data_folder do |attachment, style|
    old_path = Rails.root.join('files_old', Rails.env, 'retrieved_data', 'content', attachment.instance.id.to_s, attachment.instance.content_file_name)
    new_path = Rails.root.join('files', Rails.env, 'retrieved_data', 'content', attachment.instance.id.to_s, attachment.instance.content_file_name)
    if File.exist?(old_path) && !File.exist?(new_path)
      'files_old'
    else
      'files'
    end
  end

  scope :processed,     -> { where(state: 'processed') }
  scope :not_processed, -> { where(state: 'not_processed') }
  scope :error,         -> { where(state: 'error') }

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
    self.content = StringIO.new(SymmetricEncryption.encrypt(Oj.dump(data)))
    self.content_file_name = 'data.blob'
  end

  def json_content
    Oj.load(SymmetricEncryption.decrypt(File.read(content.path)))
  end
end
