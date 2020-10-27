# -*- encoding : UTF-8 -*-
# All prices are in cents and without VAT
# Recalculate pricing for called period
class Billing::UpdatePeriodPrice
  def initialize(period)
    @period = period
  end

  def execute
    if @period.try(:organization)
      @period.tva_ratio = @period.organization.subject_to_vat ? 1.2 : 1
    end
    create_excess_order

    @period.reload
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

  def total_price
    @period.products_price_in_cents_wo_vat + @period.excesses_price_in_cents_wo_vat
  end

  def excesses_price
    return 0 if @period.organization #excesses price of organization is saved in an order instead of period execess price

    @period.excesses_price
  end

  def create_excess_order
    return false unless @period.organization

    option = @period.reload.product_option_orders.where(name: 'excess_documents').first

    excesses_price = @period.excesses_price

    if excesses_price > 0
      option           ||=  @period.product_option_orders.new
      option.title       = "Documents et écritures comptables en excès pour les dossiers mensuels"
      option.name        = 'excess_documents'
      option.duration    = 1
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = excesses_price

      option.save
      @period.save
    elsif option.present? && option.persisted?
      option.destroy
    end
  end
end
