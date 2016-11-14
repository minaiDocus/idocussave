# -*- encoding : UTF-8 -*-
class BankAccount
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :is_for_pre_assignment

  belongs_to :user
  belongs_to :retriever
  has_many :operations, dependent: :nullify

  before_save :upcase_journal

  field :api_id
  field :api_name, default: 'budgea'

  field :bank_name
  field :name
  field :number
  field :is_used,           type: Boolean, default: false
  field :journal
  field :foreign_journal
  field :accounting_number,                default: '512000'
  field :temporary_account,                default: '471000'
  field :start_date,        type: Date

  validates_presence_of :api_id, :bank_name, :name, :number
  validate :uniqueness_of_number

  validates_presence_of :journal, :accounting_number, :start_date, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_length_of :journal, within: 2..10, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_format_of :journal, with: /\A[A-Z][A-Z0-9]*\z/, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_length_of :foreign_journal, within: 2..10, allow_nil: true

  scope :used,           -> { where(is_used: true) }
  scope :configured,     -> { where(:journal.nin => [nil, ''], :accounting_number.nin => [nil, '']) }
  scope :not_configured, -> { where(:journal.in  => [nil, ''], :accounting_number.in  => [nil, '']) }

  before_validation :set_foreign_journal, if: Proc.new { |e| e.is_for_pre_assignment }

  def configured?
    journal.present? && accounting_number.present?
  end

  def not_configured?
    !configured?
  end

private

  def upcase_journal
    self.journal = self.journal.upcase if journal_changed?
  end

  def uniqueness_of_number
    bank_account = self.user.bank_accounts.where(number: self.number).first
    if bank_account && bank_account != self
      errors.add(:number, :taken)
    end
  end

  def set_foreign_journal
    if self.journal.present?
      if self.journal.match(/\A\d/)
        self.foreign_journal = self.journal
        self.journal = 'JC' + self.foreign_journal
      else
        self.foreign_journal = nil
      end
    end
  end
end
