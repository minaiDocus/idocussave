# -*- encoding : UTF-8 -*-
class BudgeaAccount < ActiveRecord::Base
  belongs_to :user

  attr_encrypted :access_token, random_iv: true

  validates_presence_of :identifier, :encrypted_access_token

  validates :encrypted_access_token, symmetric_encryption: true
end
