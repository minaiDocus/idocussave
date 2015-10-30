# -*- encoding : UTF-8 -*-
class BankAccount
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :service_name

  belongs_to :user
  belongs_to :retriever, class_name: 'FiduceoRetriever', inverse_of: 'bank_accounts'
  has_many :operations, dependent: :nullify

  before_save :upcase_journal

  field :fiduceo_id
  field :bank_name
  field :name
  field :number
  field :journal
  field :accounting_number, default: '512000'
  field :temporary_account, default: '471000'
  field :start_date, type: Date

  validates_presence_of :fiduceo_id, :bank_name, :name, :number
  validate :uniqueness_of_number

  validates_presence_of :journal, :accounting_number, if: Proc.new { |bank_account| bank_account.persisted? }
  validates_length_of :journal, within: 2..6, if: Proc.new { |bank_account| bank_account.persisted? }
  validates_format_of :journal, with: /\A[A-Z][A-Z0-9]*\z/, if: Proc.new { |bank_account| bank_account.persisted? }

  scope :configured,     -> { where(:journal.nin => [nil, ''], :accounting_number.nin => [nil, '']) }
  scope :not_configured, -> { where(:journal.in  => [nil, ''], :accounting_number.in  => [nil, '']) }

  def configured?
    journal.present? && accounting_number.present?
  end

  def not_configured?
    !configured?
  end

  class << self
    def notify(collaborator_id, customer_id, bank_account_ids)
      bank_accounts = BankAccount.where(:_id.in => bank_account_ids)
      if bank_accounts.any?
        collaborator  = User.find collaborator_id
        customer      = User.find customer_id
        NotificationMailer.new_bank_accounts(collaborator, customer, bank_accounts).deliver
      end
    end
    handle_asynchronously :notify, priority: 1
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
end
