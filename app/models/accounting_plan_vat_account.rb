# -*- encoding : UTF-8 -*-
class AccountingPlanVatAccount < ApplicationRecord
  belongs_to :accounting_plan

  validates_presence_of :code
  validates_presence_of :nature
  validates_presence_of :account_number


  default_scope -> { order(code: :asc)}
end
