class DefaultSubscriptionOptionsService
  def initialize(period_duration=1)
    @period_duration = period_duration
    @options = []
  end

  def execute
    product = Product.where(period_duration: @period_duration).asc(:created_at).first
    groups = product.product_groups.where(:product_supergroup_ids.with_size => 0).by_position
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
    @options += group.product_options.default.by_position
  end
end
