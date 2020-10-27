# -*- encoding : UTF-8 -*-
# Gives total due amount for organization for specific period
class Billing::OrganizationBillingAmount
  def initialize(organization, time = Time.now)
    @time         = time
    @organization = organization
  end


  def execute
    Billing::PeriodBilling.amount_in_cents_wo_vat(@time.month, customer_periods) + (period.try(:price_in_cents_wo_vat) || 0)
  end


  def customer_ids
    @organization.customers.active_at(@time).pluck(:id)
  end


  def customer_subscription_ids
    Subscription.where(user_id: customer_ids).pluck(:id)
  end


  def customer_periods
    Period.where(subscription_id: customer_subscription_ids).where("start_date <= ? AND end_date >= ?", @time.to_date, @time.to_date).includes(:billings)
  end


  def period
    @period ||= @organization.subscription.find_period(@time.to_date)
  end
end
