# -*- encoding : UTF-8 -*-
class DematboxOrder
  def initialize(user, order)
    @user   = user
    @order  = order
    @period = @user.subscription.current_period
  end

  def execute
    @order.user = @user
    @order.organization = @user.organization
    @order.price_in_cents_wo_vat = 35900 * @order.dematbox_count
    if @order.save
      @period.orders << @order
      OrderMailer.delay(priority: 1).notify_dematbox_order(@order)
      UpdatePeriod.new(@period).execute
      true
    else
      false
    end
  end
end
