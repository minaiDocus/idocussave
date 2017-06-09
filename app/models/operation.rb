# -*- encoding : UTF-8 -*-
class Operation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  belongs_to :bank_account
  belongs_to :pack
  belongs_to :piece,   class_name: 'Pack::Piece',              inverse_of: :operations
  belongs_to :forced_processing_by_user, class_name: 'User',   inverse_of: :forced_processing_operations
  has_one :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :operation

  validates_presence_of :date, :label, :amount

  scope :retrieved,     -> { where(api_name: ['budgea', 'fiduceo']) }
  scope :other,         -> { where.not(api_name: ['budgea', 'fiduceo']) }
  scope :not_accessed,  -> { where(accessed_at: nil) }
  scope :not_processed, -> { where(processed_at: [nil, '']) }
  scope :processed,     -> { where.not(processed_at: [nil, '']) }
  scope :locked,        -> { where(is_locked: true) }
  scope :not_locked,    -> { where(is_locked: [nil, false]) }

  scope :recently_added,     -> { where('operations.created_at >= ?', 7.days.ago) }
  scope :not_recently_added, -> { where('operations.created_at < ?', 7.days.ago) }
  scope :forced_processing,  -> { where.not(forced_processing_at: nil) }
  scope :waiting_processing, -> { where(forced_processing_at: nil) }
  scope :not_deleted,        -> { where(deleted_at: nil) }

  scope :not_recently_added_or_forced, -> { where('operations.created_at < ? OR operations.forced_processing_at IS NOT ?', 7.days.ago, nil) }

  def self.search_for_collection(collection, contains)
    user = collection.first.user if collection.first

    collection = collection.where("label LIKE ?",    "%#{contains[:label]}%")    unless contains[:label].blank?
    collection = collection.where("category LIKE ?", "%#{contains[:category]}%") unless contains[:category].blank?

    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("date #{operator} '#{value}'")
      end
    end

    if contains[:bank_account].present? && (contains[:bank_account][:number].present? || contains[:bank_account][:bank_name].present?)
      collection = collection.joins(:bank_account)
      collection = collection.where("bank_accounts.number LIKE ?",    "%#{contains[:bank_account][:number]}%")    if contains[:bank_account][:number].present?
      collection = collection.where("bank_accounts.bank_name LIKE ?", "%#{contains[:bank_account][:bank_name]}%") if contains[:bank_account][:bank_name].present?
    end

    collection
  end

  def self.processable
    Operation.not_processed.not_deleted.not_locked.order(date: :asc).select do |operation|
      if operation.user.options.operation_processing_forced?
        true
      else
        operation.created_at < 7.days.ago || operation.forced_processing_at.present?
      end
    end
  end

  def retrieved?
    api_name.in? %w(budgea fiduceo)
  end
end
