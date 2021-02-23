# -*- encoding : UTF-8 -*-
class BankAccount < ApplicationRecord
  attr_accessor :is_for_pre_assignment

  serialize :original_currency, Hash

  belongs_to :user
  belongs_to :retriever, optional: true
  has_many :operations, dependent: :nullify

  before_save :validate_data

  validates :api_id, presence: true, :if => :not_manually_created?
  validates_presence_of :bank_name, :name, :number
  validate :uniqueness_of_number_and_bank_name
  validates :permitted_late_days, numericality: { greater_than: 0, less_than_or_equal_to: 365 }
  validates_uniqueness_of :api_id, scope: :api_name, :if => :not_manually_created?

  validates_presence_of :journal, :accounting_number, :start_date, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_presence_of :currency, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_length_of :journal, within: 2..10, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_format_of :journal, with: /\A[A-Z][A-Z0-9]*\z/, if: Proc.new { |e| e.is_for_pre_assignment }

  scope :used,           -> { where(is_used: true) }
  scope :bridge,         -> { where(api_name: 'bridge') }
  scope :configured,     -> { where.not(journal: [nil, ''], accounting_number: [nil, '']) }
  scope :not_configured, -> { where(journal: [nil, ''], accounting_number: [nil, '']) }
  scope :manual_created, -> { where(api_name: 'idocus') }
  scope :should_be_disabled, -> { manual_created.where(is_to_be_disabled: true) }

  def self.type_name_list
    ["unknown", "checking", "savings", "lifeinsurance", "market", "loan", "card", "deposit", "pea", "capitalisation", "madelin", "perp"]
  end

  def configured?
    journal.present? && accounting_number.present?
  end

  def not_configured?
    !configured?
  end


  def manual_created?
    api_name == 'idocus'
  end


  def can_be_deleted?
    manual_created? && is_to_be_disabled == false
  end


  def can_be_reopened?
    manual_created? && is_to_be_disabled == true
  end

private

  def validate_data
    set_record_value if from_idocus?

    upcase_journal
  end


  def set_record_value
    self.original_currency['prefix']    = false if original_currency['prefix']  == 'false'
    self.original_currency['precision'] = 2 if original_currency['precision']   == '2'
    self.original_currency['datetime']  = nil if original_currency['datetime']  == ''
    self.original_currency['marketcap'] = nil if original_currency['marketcap'] == ''
    self.api_id                         = self.number if self.number
  end


  def not_manually_created?
    !from_idocus?
  end


  def upcase_journal
    self.journal = journal.upcase if journal_changed?
  end


  def uniqueness_of_number_and_bank_name
    bank_account = user.bank_accounts.where(number: number, bank_name: bank_name).first

    if number
      errors.add(:number, :taken) if bank_account && bank_account != self
    end
  end


  def from_idocus?
    self.api_name == 'idocus'
  end
end
