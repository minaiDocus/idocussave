# -*- encoding : UTF-8 -*-
class OrganizationBillingAmountService
  def initialize(organization, time=Time.now)
    @organization = organization
    @time = time
  end

  def execute
    PeriodBillingService.amount_in_cents_wo_vat(PeriodBillingService.order_of(@time), customer_periods) +
      options.sum(&:price_in_cents_wo_vat)
  end

  def customer_ids
    @organization.customers.active_at(@time).distinct(:_id)
  end

  def customer_subscription_ids
    Subscription.where(:user_id.in => customer_ids).distinct(:_id)
  end

  def customer_periods
    Period.any_in(subscription_id: customer_subscription_ids).where(
      :start_at.lte => @time,
      :end_at.gte => @time
    )
  end

  def period
    @period ||= @organization.subscription.find_period(@time)
  end

  def options
    if period
      period.product_option_orders.select do |option|
        option.group_position >= 1000
      end
    else
      []
    end
  end
end
