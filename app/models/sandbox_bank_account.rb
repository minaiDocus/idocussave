# -*- encoding : UTF-8 -*-
class SandboxBankAccount < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :retriever, optional: true
  has_many :sandbox_operations, dependent: :nullify

  # field :api_id
  # field :api_name, default: 'budgea'
  # field :bank_name
  # field :name
  # field :number
  # field :is_used,           type: Boolean, default: false
  # field :journal
  # field :foreign_journal
  # field :accounting_number,                default: '512000'
  # field :temporary_account,                default: '471000'
  # field :start_date,        type: Date

  validates_presence_of :api_id, :bank_name, :name, :number
  validate :uniqueness_of_number

  def configured?
    false
  end

private

  def uniqueness_of_number
    bank_account = self.user.bank_accounts.where(number: self.number).first
    if bank_account && bank_account != self
      errors.add(:number, :taken)
    end
  end
end
