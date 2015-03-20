# -*- encoding : UTF-8 -*-
# All prices are in cents and without VAT
class UpdatePeriodPriceService
  def initialize(period)
    @period = period
  end

  def execute
    @period.recurrent_products_price_in_cents_wo_vat = recurrent_price
    @period.ponctual_products_price_in_cents_wo_vat  = ponctual_price
    @period.products_price_in_cents_wo_vat           = options_price
    @period.excesses_price_in_cents_wo_vat           = excesses_price
    @period.price_in_cents_wo_vat                    = total_price
    @period.save
  end

private

  def recurrent_options
    @period.product_option_orders.select do |option|
      option.duration == 0
    end
  end

  def ponctual_options
    @period.product_option_orders.select do |option|
      option.duration == 1
    end
  end

  def extra_options
    @period.product_option_orders.select do |option|
      option.group_position >= 1000
    end
  end

  def recurrent_price
    amount = recurrent_options.sum(&:price_in_cents_wo_vat)
    if @period.duration == 3
      (amount / 3).round
    else
      amount
    end
  end

  def ponctual_price
    ponctual_options.sum(&:price_in_cents_wo_vat)
  end

  def options_price
    recurrent_options.sum(&:price_in_cents_wo_vat) + @period.ponctual_products_price_in_cents_wo_vat
  end

  def excesses_price
    @period.price_in_cents_of_excess_scan +
    @period.price_in_cents_of_excess_uploaded_pages +
    @period.price_in_cents_of_excess_dematbox_scanned_pages +
    @period.price_in_cents_of_excess_compta_pieces
  end

  def total_price
    if @period.user
      @period.products_price_in_cents_wo_vat + @period.excesses_price_in_cents_wo_vat
    else
      extra_options.sum(&:price_in_cents_wo_vat)
    end
  end
end
