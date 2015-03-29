# -*- encoding : UTF-8 -*-
class GoogleDoc
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :external_file_storage

  field :token,                               default: ''
  field :refresh_token,                       default: ''
  field :token_expires_at,     type: Time
  field :is_configured,        type: Boolean, default: false
  field :path,                                default: 'iDocus/:code/:year:month/:account_book/'
  field :file_type_to_deliver, type: Integer, default: ExternalFileStorage::PDF

  def is_configured?
    is_configured
  end

  def reset
    update_attributes(token: '', refresh_token: '', token_expires_at: nil, is_configured: false)
  end

  def sync(remote_files)
    GoogleDriveSyncService.new(self).sync(remote_files)
  end

  def user
    external_file_storage.user
  end
end
