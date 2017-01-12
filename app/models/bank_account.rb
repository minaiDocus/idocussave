# -*- encoding : UTF-8 -*-
class BankAccount < ActiveRecord::Base
  attr_accessor :is_for_pre_assignment

  belongs_to :user
  belongs_to :retriever
  has_many :operations, dependent: :nullify

  before_save :upcase_journal
  before_validation :set_foreign_journal, if: proc { |bank_account| bank_account.persisted? }

  # TODO add those fields through migration
  # field :api_id
  # field :api_name, default: 'budgea'

  validates_presence_of :api_id, :bank_name, :name, :number
  validate :uniqueness_of_number

  validates_presence_of :journal, :accounting_number, :start_date, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_length_of :journal, within: 2..10, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_format_of :journal, with: /\A[A-Z][A-Z0-9]*\z/, if: Proc.new { |e| e.is_for_pre_assignment }
  validates_length_of :foreign_journal, within: 2..10, allow_nil: true

  scope :used,           -> { where(is_used: true) }
  scope :configured,     -> { where.not(journal:[nil, ''], accounting_number: [nil, '']) }
  scope :not_configured, -> { where(journal: [nil, ''], accounting_number: [nil, '']) }

  before_validation :set_foreign_journal, if: Proc.new { |e| e.is_for_pre_assignment }

  def configured?
    journal.present? && accounting_number.present?
  end

  def not_configured?
    !configured?
  end

private

  def upcase_journal
    self.journal = journal.upcase if journal_changed?
  end

  def uniqueness_of_number
    bank_account = user.bank_accounts.where(number: number).first

    errors.add(:number, :taken) if bank_account && bank_account != self
  end

  def set_foreign_journal
    if journal.present?
      if journal =~ /\A\d/
        self.foreign_journal = journal
        self.journal = 'JC' + foreign_journal
      else
        self.foreign_journal = nil
      end
    end
  end
end
