class DefaultSubscriptionOptionsService
  def initialize(period_duration=1)
    @period_duration = period_duration
    @options = []
  end

  def execute
    product = Product.where(period_duration: @period_duration).asc(:created_at).first
    groups = product.product_groups.where(:product_supergroup_ids.size => 0).by_position
    groups.each do |group|
      walk_into_group(group)
    end
    @options
  end

private

  def walk_into_group(group)
    group.product_subgroups.by_position.each do |subgroup|
      walk_into_group(subgroup)
    end
    group.product_options.default.by_position.each do |option|
      option_order = order_option(option)
      quantity = required_option(group).try(:quantity) || 1
      option_order.price_in_cents_wo_vat *= quantity
      @options << option_order
    end
  end

  def required_option(group)
    if group.product_require
      group.product_require.product_options.default.asc(:quantity).first
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
    order
  end
end
