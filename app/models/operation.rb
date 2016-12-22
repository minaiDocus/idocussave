# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class Operation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  belongs_to :bank_account
  belongs_to :pack
  belongs_to :piece,   class_name: 'Pack::Piece',              inverse_of: :operations
  has_one :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :operation


  validates_presence_of :date, :label, :amount


  scope :fiduceo,       -> { where.not(fiduceo_id: [nil, '']) }
  scope :other,         -> { where(fiduceo_id: [nil, '']) }
  scope :not_accessed,  -> { where(accessed_at: nil) }
  scope :not_processed, -> { where(processed_at: [nil, '']) }
  scope :processed,     -> { where.not(processed_at: [nil, '']) }
  scope :locked,        -> { where(is_locked: true) }
  scope :not_locked,    -> { where(is_locked: [nil, false]) }


  def self.search_for_collection(collection, contains)
    user = collection.first.user

    collection = collection.where("label LIKE ?",    "%#{contains[:label]}%")    unless contains[:label].blank?
    collection = collection.where("category LIKE ?", "%#{contains[:category]}%") unless contains[:category].blank?


    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("date #{operator} '#{value}'")
      end
    end

    if contains[:bank_account].present? && (contains[:bank_account][:bank_name].present? || contains[:bank_account][:number].present?)
      bank_name = begin
                    contains[:bank_account][:bank_name]
                  rescue
                    nil
                  end
      number    = begin
                    contains[:bank_account][:number]
                  rescue
                    nil
                  end

      bank_accounts = user.bank_accounts
      bank_accounts = bank_accounts.where("number LIKE ?", "%#{number}%")       if number.present?
      bank_accounts = bank_accounts.where("bank_name LIKE ?", "%#{bank_name}%") if bank_name.present?

      collection = collection.where(bank_account_id: bank_accounts.pluck(:id))
    end

    collection
  end
end
