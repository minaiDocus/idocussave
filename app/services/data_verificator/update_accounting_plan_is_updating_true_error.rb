# -*- encoding : UTF-8 -*-
class DataVerificator::UpdateAccountingPlanIsUpdatingTrueError < DataVerificator::DataVerificator
  def execute
    accounting_plans = AccountingPlan.where("last_checked_at < ? AND is_updating = ?", 6.hours.ago, true)

    counter = 0

    messages = []

    accounting_plans.each do |accounting_plan|
      counter += 1
      messages << "accounting_plan_id: #{accounting_plan.id}, accounting_plan_user_code: #{accounting_plan.user.code}"

      accounting_plan.update(is_updating: false)
    end

    {
      title: "UpdateAccountingPlanIsUpdatingTrueError - #{counter} UpdateAccountingPlan(s) with is_updating true and last checked is before 6 hours ago",
      type: "table",
      message: messages.join('; ')
    }
  end
end