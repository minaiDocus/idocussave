# -*- encoding : UTF-8 -*-
class PeriodBillingService
  def initialize(period)
    @period = period
  end

  def amount_in_cents_wo_vat(order)
    if @period.duration == 1
      @period.price_in_cents_wo_vat
    elsif @period.duration == 3
      if @period.billings.any?
        billing = @period.billings.where(order: order).first
        if billing
          billing.amount_in_cents_wo_vat
        else
          not_billed_count = 3 - @period.billings.size
          amount = (@period.products_price_in_cents_wo_vat - @period.billings.sum(:amount_in_cents_wo_vat))
          amount /= not_billed_count
          amount += @period.excesses_price_in_cents_wo_vat if order == 3
          amount
        end
      else
        if order == 1
          @period.recurrent_products_price_in_cents_wo_vat + @period.ponctual_products_price_in_cents_wo_vat
        elsif order == 2
          @period.recurrent_products_price_in_cents_wo_vat
        elsif order == 3
          @period.recurrent_products_price_in_cents_wo_vat + @period.excesses_price_in_cents_wo_vat
        end
      end
    end
  end

  def save(order)
    unless @period.billings.where(order: order).first
      billing = PeriodBilling.new
      billing.amount_in_cents_wo_vat = amount_in_cents_wo_vat(order)
      billing.order = order
      @period.billings << billing
      @period.save
    end
  end

  def fill_past_with_0
    if @period.duration == 3 && Time.now.month != Time.now.beginning_of_quarter.month
      2.times.each do |i|
        time = @period.start_at + i.month
        if time.month < Time.now.month
          billing = PeriodBilling.new
          billing.order = i+1
          billing.amount_in_cents_wo_vat = 0
          @period.billings << billing
          @period.save
        end
      end
    end
  end

  class << self
    def amount_in_cents_wo_vat(order, periods)
      periods.map do |period|
        new(period).amount_in_cents_wo_vat(order)
      end.sum
    end

    def order_of(time)
      order = time.month % 3
      order == 0 ? 3 : order
    end

    def vat_ratio(time)
      if time < Time.local(2014,1,1)
        1.196
      else
        1.2
      end
    end
  end
end
