# -*- encoding : UTF-8 -*-
# Format periods for XLS reporting
class Organization::MonthlyReport
  def initialize(organization_id, customer_ids, time)
    @time = time
    @customer_ids    = customer_ids
    @organization_id = organization_id
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
    @periods ||= Period.where('user_id IN (?) OR organization_id = ?', @customer_ids, @organization_id).where("start_date <= ? AND end_date >= ?", @time.to_date, @time.to_date)
  end


  def price_in_cents_wo_vat
    @price_in_cents_wo_vat ||= Billing::PeriodBilling.amount_in_cents_wo_vat(@time.month, periods)
  end


  def formatted_price
    ('%0.2f' % (price_in_cents_wo_vat.round / 100.0)).tr('.', ',')
  end
end
