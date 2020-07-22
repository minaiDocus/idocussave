# -*- encoding : UTF-8 -*-
class Archive::Retriever < ApplicationRecord
  self.table_name = 'archive_retrievers'

  validates_uniqueness_of :budgea_id

  belongs_to :owner, class_name: 'Archive::BudgeaUser', inverse_of: :archive_retrievers

  scope :updated,   -> { where(is_updated: true) }
  scope :exist,     -> { where(exist: true) }
  scope :not_exist, -> { where(exist: false) }
  scope :active,    -> { where(active: true) }

  def stored_retriever
    Retriever.where(budgea_id: self.budgea_id).first
  end
end