# -*- encoding : UTF-8 -*-
class Operation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user,                                                                     index: true
  belongs_to :bank_account,                                                             index: true
  belongs_to :pack
  belongs_to :piece,   class_name: 'Pack::Piece',              inverse_of: :operations
  has_one :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :operation

  # TODO add those indexes
  # index({ api_id: 1 })
  # index({ api_name: 1 })

  # TODO add those fields through migration
  # field :api_id
  # field :api_name

  # TODO review these field
  # field :type

  validates_presence_of :date, :label, :amount

  scope :retrieved,     -> { where.not(api_id: [nil, '']) }
  scope :other,         -> { where(api_id: [nil, '']) }
  scope :not_accessed,  -> { where(accessed_at: nil) }
  scope :not_processed, -> { where(processed_at: [nil, '']) }
  scope :processed,     -> { where.not(processed_at: [nil, '']) }
  scope :locked,        -> { where(is_locked: true) }
  scope :not_locked,    -> { where(is_locked: [nil, false]) }


  def self.search_for_collection(collection, contains)
    user = collection.first.user if collection.first

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
