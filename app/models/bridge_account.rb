class BridgeAccount < ApplicationRecord
  belongs_to :user

  attr_encrypted :username, random_iv: true
  attr_encrypted :password, random_iv: true

  validates_presence_of :identifier, :encrypted_username, :encrypted_password
  validates_presence_of :user
  validates :encrypted_username, symmetric_encryption: true
  validates :encrypted_password, symmetric_encryption: true
end
