# -*- encoding : UTF-8 -*-
class OrganizationMonthlyReport
  def initialize(organization_id, customer_ids, time)
    @organization_id = organization_id
    @customer_ids    = customer_ids
    @time            = time
  end

  def execute
    if price_in_cents_wo_vat > 0
      [formatted_price, periods.reject(&:organization).size]
    else
      [nil, nil]
    end
  end

private

  def periods
    @periods ||= Period.any_of({ :user_id.in => @customer_ids }, { organization_id: @organization_id }).
      where(:start_at.lte => @time.dup, :end_at.gte => @time.dup).entries
  end

  def price_in_cents_wo_vat
    @price_in_cents_wo_vat ||= PeriodBillingService.amount_in_cents_wo_vat(@time.month, periods)
  end

  def formatted_price
    ("%0.2f" % (price_in_cents_wo_vat.round/100.0)).gsub('.', ',')
  end
end
