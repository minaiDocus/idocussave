# -*- encoding : UTf-8 -*-
class AccountingPlan::UpdateService
  def initialize(user)
    @user = user
    @accounting_plan = user.accounting_plan
  end

  def run
    execute
  end

  private

  def execute; end

  def create_item(data)
  	item = AccountingPlanItem.find_by_name_and_account(@accounting_plan.id, data[:name], data[:number]) || AccountingPlanItem.new
    item.third_party_name    = data[:name]
    item.third_party_account = data[:number]
    item.conterpart_account  = data[:associate]
    item.code                = data[:code]
    item.is_updated          = true

    item.kind 				       = data[:kind]
    @accounting_plan.customers << item if item.kind == 'customer'
    @accounting_plan.providers << item if item.kind == 'provider'
  end
end