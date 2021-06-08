# -*- encoding : UTF-8 -*-
class Operation < ApplicationRecord
  serialize :currency, Hash

  attr_accessor :temp_currency

  belongs_to :organization
  belongs_to :user
  belongs_to :bank_account
  belongs_to :pack, optional: true
  belongs_to :piece,   class_name: 'Pack::Piece',              inverse_of: :operations, optional: true
  belongs_to :forced_processing_by_user, class_name: 'User',   inverse_of: :forced_processing_operations, optional: true
  belongs_to :cedricom_reception, optional: true
  has_one :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :operation
  has_one :temp_preseizure,  class_name: 'Pack::Report::TempPreseizure', inverse_of: :operation

  validates_presence_of :date, :label, :amount

  validates_uniqueness_of :api_id, scope: :api_name, :if => :not_cap_idocus_and_not_ebics?

  scope :retrieved,     -> { where(api_name: ['budgea', 'fiduceo']) }
  scope :other,         -> { where.not(api_name: ['budgea', 'fiduceo']) }
  scope :not_accessed,  -> { where(accessed_at: nil) }
  scope :not_processed, -> { where(processed_at: [nil, '']) }
  scope :processed,     -> { where.not(processed_at: nil) }
  scope :locked,        -> { where(is_locked: true) }
  scope :not_locked,    -> { where(is_locked: [nil, false]) }

  scope :recently_added,     -> { where('operations.created_at >= ?', 7.days.ago) }
  scope :not_recently_added, -> { where('operations.created_at < ?', 7.days.ago) }
  scope :forced_processing,  -> { where.not(forced_processing_at: nil) }
  scope :waiting_processing, -> { where(forced_processing_at: nil) }
  scope :not_deleted,        -> { where(deleted_at: nil) }
  scope :with_api_id,        -> { where.not(api_id: nil) }

  scope :not_duplicated,    -> { where.not('comment LIKE "%Locked for duplication%"') }
  scope :duplicated,        -> { where('comment LIKE "%Locked for duplication%"') }

  scope :not_recently_added_or_forced, -> { where('operations.created_at < ? OR operations.forced_processing_at IS NOT ?', 7.days.ago, nil) }
  scope :with,                         -> (period) { where(updated_at: period) }

  after_save do |operation|
    Rails.cache.write(['user', operation.user.id, 'operations', 'last_updated_at'], Time.now.to_i)
  end

  def self.search_for_collection(collection, contains)
    user = collection.first.user if collection.first

    collection = collection.processed                                    if contains[:pre_assigned] == "pre_assigned"
    collection = collection.locked                                       if contains[:pre_assigned] == "not_pre_assigned"
    collection = collection.waiting_processing.not_locked.not_processed  if contains[:pre_assigned] == "is_waiting"

    collection = collection.where("label LIKE ?",    "%#{contains[:label]}%")    unless contains[:label].blank?
    collection = collection.where("category LIKE ?", "%#{contains[:category]}%") unless contains[:category].blank?

    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("date #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:value_date]
      contains[:value_date].each do |operator, value|
        collection = collection.where("value_date #{operator} ?", value) if operator.in?(['>=', '<='])
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
    users_accounting_plan_updating = AccountingPlan.updating.pluck(:user_id).uniq

    operations = Operation.with_api_id.not_processed.not_deleted.not_locked.where.not(user_id: users_accounting_plan_updating).where('created_at < ? OR forced_processing_at IS NOT NULL', 1.week.ago).order(date: :asc).includes(:user, :pack, :bank_account)

    user_ids = Operation.with_api_id.not_processed.not_deleted.not_locked.where.not(user_id: users_accounting_plan_updating).where('created_at > ? AND forced_processing_at IS NULL', 1.week.ago).pluck(:user_id).uniq
    users = User.find user_ids
    forced_user_ids = users.select { |user| user.options.operation_processing_forced? }.map(&:id)
    forced_operations = Operation.with_api_id.not_processed.not_deleted.not_locked.where('created_at > ? AND forced_processing_at IS NULL', 1.week.ago).where(user_id: forced_user_ids).includes(:user, :pack, :bank_account)

    operations + forced_operations
  end

  def self.select_with(_api_name, period)
    Operation.with(period).where(api_name: _api_name)
  end

  def old?
    bank_account = self.bank_account

    bank_account.lock_old_operation &&
    bank_account.created_at < 1.month.ago &&
    self.date < bank_account.permitted_late_days.days.ago.to_date
  end

  def to_lock?
    bank_account = self.bank_account

    bank_account.nil? || (bank_account.start_date.present? && self.date < bank_account.start_date) ||
    self.date < Date.parse('2017-01-01') ||
    self.is_coming || old?
  end

  def need_conversion?
    currency['id'] != bank_account.currency
  end

  def retrieved?
    api_name.in? %w(budgea fiduceo)
  end

  def credit?
    self.amount < 0
  end

  def debit?
    self.amount >= 0
  end

  def not_cap_idocus_and_not_ebics?
    self.api_name != 'capidocus' && self.api_name != 'cedricom'
  end
end
