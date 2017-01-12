# -*- encoding : UTF-8 -*-
# Create a dematbox order
class OrderDematbox
  def initialize(user, order, is_an_update = false)
    @user         = user
    @order        = order
    @period       = user.subscription.current_period
    @is_an_update = is_an_update
  end


  def execute
    @order.user ||= @user
    @order.organization ||= @user.organization
    @order.price_in_cents_wo_vat = 35_900 * @order.dematbox_count
    @order.address.is_for_dematbox_shipping = true if @order.address

    if @order.save
      unless @is_an_update
        @period.orders << @order
        ConfirmOrder.delay_for(24.hours).execute(@order.id)
      end

      UpdatePeriod.new(@period).execute

      true
    else
      false
    end
  end
end
