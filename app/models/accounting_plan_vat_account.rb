# -*- encoding : UTF-8 -*-
class AccountingPlanVatAccount
  include Mongoid::Document

  embedded_in :accounting_plan

  field :code
  field :nature
  field :account_number

  validates_presence_of :code
  validates_presence_of :nature
  validates_presence_of :account_number

  default_scope -> { asc(:code) }

  def self.find_by_code(code)
    where(code: code).first
  end
end
