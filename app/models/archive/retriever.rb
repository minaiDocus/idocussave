# -*- encoding : UTF-8 -*-
class Archive::Retriever < ApplicationRecord
  self.table_name = 'archive_retrievers'

  validates_uniqueness_of :budgea_id

  belongs_to :owner, class_name: 'Archive::BudgeaUser', inverse_of: :archive_retrievers

  scope :updated,   -> { where(is_updated: true) }
  scope :exist,     -> { where(exist: true) }
  scope :not_exist, -> { where(exist: false) }
  scope :active,    -> { where(active: true) }
  scope :not_deleted,    -> { where(is_deleted: false) }

  def stored_retriever
    Retriever.where(budgea_id: self.budgea_id).first
  end

  class << self
    def search(contains)
      archive_budgea_retrievers = Archive::Retriever.all

      if contains[:created]
        contains[:created].each do |operator, value|
          archive_budgea_retrievers = archive_budgea_retrievers.where("created #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:deleted_date]
        contains[:deleted_date].each do |operator, value|
          archive_budgea_retrievers = archive_budgea_retrievers.where("deleted_date #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      archive_budgea_retrievers = archive_budgea_retrievers.where(owner_id:           contains[:owner_id])  if contains[:owner_id].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(budgea_id:          contains[:budgea_id]) if contains[:budgea_id].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(id_connector:    contains[:id_connector]) if contains[:id_connector].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where("state LIKE ?", "%#{contains[:state]}%")  if contains[:state].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where("error LIKE ?", "%#{contains[:error]}%")  if contains[:error].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where("error_message LIKE ?", "%#{contains[:error_message]}%") if contains[:error_message].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(active:             contains[:active])         if contains[:active].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(exist:             contains[:exist])           if contains[:exist].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(is_updated:        contains[:is_updated])      if contains[:is_updated].present?
      archive_budgea_retrievers = archive_budgea_retrievers.where(is_deleted:        contains[:is_deleted])      if contains[:is_deleted].present?

      archive_budgea_retrievers
    end

    def search_for_collection(collection, contains)
      collection = collection.where(is_updated: contains[:is_updated]) unless contains[:is_updated].blank?
      collection = collection.where('state LIKE ?', "%#{contains[:state]}%") unless contains[:state].blank?
      collection = collection.where('error LIKE ?', "%#{contains[:error]}%") unless contains[:error].blank?
      collection
    end
  end
end