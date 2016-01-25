# -*- encoding : UTF-8 -*-
class OrderDematbox
  def initialize(user, order, is_an_update=false)
    @user         = user
    @order        = order
    @period       = user.subscription.current_period
    @is_an_update = is_an_update
  end

  def execute
    @order.user ||= @user
    @order.organization ||= @user.organization
    @order.price_in_cents_wo_vat = 35900 * @order.dematbox_count
    if @order.save
      unless @is_an_update
        @period.orders << @order
        ConfirmOrder.execute(@order.id.to_s)
      end
      UpdatePeriod.new(@period).execute
      true
    else
      false
    end
  end
end
