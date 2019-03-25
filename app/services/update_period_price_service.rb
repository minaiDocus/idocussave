# -*- encoding : UTF-8 -*-
# All prices are in cents and without VAT
# Recalculate pricing for called period
class UpdatePeriodPriceService
  def initialize(period)
    @period = period
  end

  def execute
    if @period.try(:organization)
      @period.tva_ratio = @period.organization.subject_to_vat ? 1.2 : 1
    end
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
    @period.price_in_cents_of_excess_compta_pieces  +
    @period.price_in_cents_of_excess_uploaded_pages +
    @period.price_in_cents_of_excess_dematbox_scanned_pages +
    @period.price_in_cents_of_excess_paperclips
  end

  def total_price
    @period.products_price_in_cents_wo_vat + @period.excesses_price_in_cents_wo_vat
  end
end
