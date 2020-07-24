# -*- encoding : UTF-8 -*-
class Archive::BudgeaUser < ApplicationRecord
  self.table_name = 'archive_budgea_users'

  attr_encrypted :access_token, random_iv: true

  validates_uniqueness_of :identifier
  validates :encrypted_access_token, symmetric_encryption: true

  has_many :archive_retrievers, foreign_key: :owner_id, class_name: 'Archive::Retriever'

  scope :has_token, -> { where.not(encrypted_access_token: nil) }
  scope :updated,   -> { where(is_updated: true) }
  scope :exist,     -> { where(exist: true) }
  scope :not_exist, -> { where(exist: false) }
  scope :not_deleted, -> { where(is_deleted: false) }

  def stored_account
    BudgeaAccount.where(identifier: self.identifier).first
  end
end