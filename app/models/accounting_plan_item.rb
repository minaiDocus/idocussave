# -*- encoding : UTF-8 -*-
class AccountingPlanItem < ApplicationRecord
  attr_accessor :no_third_party_account

  validates_presence_of :third_party_name
  validates_presence_of :third_party_account, unless: Proc.new { |item| item.no_third_party_account }

  default_scope -> { order(third_party_name: :asc) }

  def self.find_by_name(name)
    where(third_party_name: name).first
  end

  def self.find_by_name_and_account(accounting_plan_id, name, account)
    where(accounting_plan_itemable_id: accounting_plan_id, third_party_name: name, third_party_account: account, accounting_plan_itemable_type: 'AccountingPlan').first
  end
end
