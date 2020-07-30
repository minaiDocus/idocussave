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

  class << self
    def search(contains)
      archive_budgea_users = Archive::BudgeaUser.all

      if contains[:signin]
        contains[:signin].each do |operator, value|
          archive_budgea_users = archive_budgea_users.where("signin #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:deleted_date]
        contains[:deleted_date].each do |operator, value|
          archive_budgea_users = archive_budgea_users.where("deleted_date #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      archive_budgea_users = archive_budgea_users.where(identifier:        contains[:identifier])      if contains[:identifier].present?
      archive_budgea_users = archive_budgea_users.where("platform LIKE ?", "%#{contains[:platform]}%") if contains[:platform].present?
      archive_budgea_users = archive_budgea_users.where(exist:             contains[:exist])           if contains[:exist].present?
      archive_budgea_users = archive_budgea_users.where(is_updated:        contains[:is_updated])      if contains[:is_updated].present?
      archive_budgea_users = archive_budgea_users.where(is_deleted:        contains[:is_deleted])      if contains[:is_deleted].present?

      archive_budgea_users
    end

    def search_for_collection(collection, contains)
      collection = collection.where(is_updated: contains[:is_updated]) unless contains[:is_updated].blank?
      collection = collection.where('platform LIKE ?', "%#{contains[:platform]}%") unless contains[:platform].blank?
      collection
    end
  end
end