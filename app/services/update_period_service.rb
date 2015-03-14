# -*- encoding : UTF-8 -*-
class UpdatePeriodService
  def initialize(period)
    @period       = period
    @subscription = period.subscription
  end

  def execute
    @period.duration = @subscription.period_duration
    copyable_keys.each do |key|
      @period[key] = @subscription[key]
    end
    @period.product_option_orders = product_option_orders
    UpdatePeriodPriceService.new(@period).execute if @period.save
  end

  def options
    if @subscription.organization
      options = @subscription.options.select { |o| o.group_position >= 1000 }
    else
      options = @subscription.options
    end
    options.sort_by(&:group_position)
  end

  def product_option_orders
    options.map { |option| order_option(option) }
  end

private

  def required_option(group)
    if group && group.product_require
      group.product_require.product_options.where(:_id.in => options.map(&:id)).first
    else
      nil
    end
  end

  def order_option(option)
    order = ProductOptionOrder.new
    order.fields.keys.each do |k|
      setter =  (k+"=").to_sym
      value = option.send(k)
      order.send(setter, value)
    end
    quantity = required_option(option.product_group).try(:quantity) || 1
    order.price_in_cents_wo_vat *= quantity
    order
  end

  def copyable_keys
    [
      :max_sheets_authorized,
      :max_upload_pages_authorized,
      :max_preseizure_pieces_authorized,
      :max_expense_pieces_authorized,
      :max_paperclips_authorized,
      :max_oversized_authorized,
      :max_dematbox_scan_pages_authorized,
      :unit_price_of_excess_sheet,
      :unit_price_of_excess_upload,
      :unit_price_of_excess_preseizure,
      :unit_price_of_excess_expense,
      :unit_price_of_excess_paperclips,
      :unit_price_of_excess_oversized,
      :unit_price_of_excess_dematbox_scan
    ]
  end
end
