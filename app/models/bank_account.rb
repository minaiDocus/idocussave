# -*- encoding : UTF-8 -*-
class BankAccount < ActiveRecord::Base
  attr_accessor :service_name


  belongs_to :user
  belongs_to :retriever, class_name: 'FiduceoRetriever', inverse_of: 'bank_accounts'
  has_many :operations, dependent: :nullify


  before_save :upcase_journal
  before_validation :set_foreign_journal, if: proc { |bank_account| bank_account.persisted? }



  validate :uniqueness_of_number
  validates_length_of :journal, within: 2..10, if: proc { |bank_account| bank_account.persisted? }
  validates_length_of :foreign_journal, within: 2..10, allow_nil: true
  validates_format_of :journal, with: /\A[A-Z][A-Z0-9]*\z/, if: proc { |bank_account| bank_account.persisted? }
  validates_presence_of :journal,    :accounting_number, :start_date, if: proc { |bank_account| bank_account.persisted? }
  validates_presence_of :fiduceo_id, :bank_name, :name, :number


  scope :outdated,       -> { where(is_operations_up_to_date: false) }
  scope :configured,     -> { where.not(journal:[nil, ''], accounting_number: [nil, '']) }
  scope :not_configured, -> { where(journal: [nil, ''], accounting_number: [nil, '']) }



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
