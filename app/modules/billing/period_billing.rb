# -*- encoding : UTF-8 -*-
class Billing::PeriodBilling
  def initialize(period)
    @period = period
  end

  def self.amount_in_cents_wo_vat(order, periods)
    periods.map do |period|
      new(period).amount_in_cents_wo_vat(order)
    end.sum
  end

  def self.quarter_order_of(number)
    order = number % 3
    order == 0 ? 3 : order
  end

  def self.vat_ratio(time)
    if time.to_date < Time.local(2014, 1, 1).to_date
      1.196
    else
      1.2
    end
  end

  def amount_in_cents_wo_vat(order)
    if @period.duration == 1
      @period.price_in_cents_wo_vat
    elsif @period.duration == 3
      quarter_order = Billing::PeriodBilling.quarter_order_of(order)
      if @period.billings.any?
        billing = @period.billings.where(order: quarter_order).first
        if billing
          billing.amount_in_cents_wo_vat
        else
          not_billed_count = 3 - @period.billings.size
          amount = (@period.products_price_in_cents_wo_vat - @period.billings.sum(:amount_in_cents_wo_vat))
          amount /= not_billed_count
          amount += @period.excesses_price_in_cents_wo_vat if quarter_order == 3
          amount
        end
      else
        if quarter_order == 1
          @period.recurrent_products_price_in_cents_wo_vat + @period.ponctual_products_price_in_cents_wo_vat
        elsif quarter_order == 2
          @period.recurrent_products_price_in_cents_wo_vat
        elsif quarter_order == 3
          @period.recurrent_products_price_in_cents_wo_vat + @period.excesses_price_in_cents_wo_vat
        end
      end
    elsif @period.duration == 12
      find_or_compute(:amount_in_cents_wo_vat, order)
    end
  end

  def data(key, order)
    case @period.duration
    when 1
      @period.send(key)
    when 3
      order.in?([3, 6, 9, 12]) ? @period.send(key) : 0
    when 12
      find_or_compute(key, order)
    end
  end

  def next_order
    @period.billings.map(&:order).max + 1
  rescue
    1
  end

  def save(order)
    case @period.duration
    when 1
      _order = 1
    when 3
      _order = Billing::PeriodBilling.quarter_order_of(order)
    when 12
      _order = order
    end

    unless @period.billings.where(order: _order).first
      billing = PeriodBilling.new
      billing.amount_in_cents_wo_vat = amount_in_cents_wo_vat(_order)

      attributes.each do |attribute|
        billing.send("#{attribute}=", data(attribute, order))
      end

      billing.order = _order
      @period.billings << billing
      @period.save
    end
  end

  def fill_past_with_0
    order   = 1
    month = @period.start_date.month
    while month < Time.now.month
      fill_with_0(order)
      order += 1
      month += 1
    end
  end

  def fill_with_0(order)
    billing = PeriodBilling.new(order: order)
    @period.billings << billing
    @period.save
  end

private

  def find_or_compute(key, order)
    billing = @period.billings.where(order: order).first
    if billing
      billing.send(key)
    elsif order == next_order
      billed = @period.billings.to_a.sum(&key) || 0
      @period.send(key) - billed
    else
      0
    end
  end

  def attributes
    [
      :scanned_pieces,
      :scanned_sheets,
      :scanned_pages,
      :dematbox_scanned_pieces,
      :dematbox_scanned_pages,
      :uploaded_pieces,
      :uploaded_pages,
      :retrieved_pieces,
      :retrieved_pages,
      :preseizure_pieces,
      :expense_pieces,
      :paperclips,
      :oversized,
      :excess_sheets,
      :excess_uploaded_pages,
      :excess_dematbox_scanned_pages,
      :excess_compta_pieces,
      :excesses_amount_in_cents_wo_vat
    ]
  end
end
