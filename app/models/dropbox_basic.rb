# -*- encoding : UTF-8 -*-
class DropboxBasic < ActiveRecord::Base
  serialize :attachment_names
  serialize :import_folder_paths

  belongs_to :external_file_storage

  validate :beginning_of_path


  before_create :initialize_serialized_attributes

  before_destroy do
    self.class.disable_access_token(access_token) if access_token.present?
  end


  def self.disable_access_token(access_token)
    client = DropboxClient.new(access_token, Dropbox::ACCESS_TYPE)
    client.disable_access_token
  end


  def user
    external_file_storage.user
  end


  def is_configured?
    access_token.present?
  end


  def is_used?
    external_file_storage.is_used?(ExternalFileStorage::F_DROPBOX)
  end


  private


  def beginning_of_path
    errors.add(:path, :invalid) if path =~ /\A\/*exportation vers iDocus/
  end


  def initialize_serialized_attributes
    self.import_folder_paths ||= []
  end
end
