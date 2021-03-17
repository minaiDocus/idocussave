# -*- encoding : UTF-8 -*-
class DropboxBasic < ApplicationRecord
  serialize :attachment_names
  serialize :import_folder_paths

  attr_encrypted :access_token, random_iv: true

  validates :encrypted_access_token, symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_access_token.nil? }
  validate :beginning_of_path

  belongs_to :external_file_storage

  before_create :initialize_serialized_attributes

  before_destroy do
    begin
      DropboxApi::Client.new(access_token).revoke_token if access_token.present?
    rescue DropboxApi::Errors::HttpError => e
      raise unless e.message.match(/invalid_access_token/)
    end
  end

  def user
    external_file_storage.user
  end

  def need_to_check_for_all?
    checked_at_for_all.present? && checked_at_for_all <= 24.hours.ago
  end

  def is_configured?
    access_token.present?
  end
  alias_method :configured?, :is_configured?

  def is_used?
    external_file_storage.is_used?(ExternalFileStorage::F_DROPBOX)
  end
  alias_method :used?, :is_used?

  def enable
    external_file_storage.use ExternalFileStorage::F_DROPBOX
  end

  def disable
    external_file_storage.unuse ExternalFileStorage::F_DROPBOX
  end

  def reset_access_token
    update access_token: nil
  end

private

  def beginning_of_path
    errors.add(:path, :invalid) if path =~ /\A\/*exportation vers iDocus/
  end

  def initialize_serialized_attributes
    self.import_folder_paths ||= []
  end
end
