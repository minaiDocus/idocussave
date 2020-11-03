# -*- encoding : UTF-8 -*-
class Order::Destroy
  def initialize(order)
    @order = order
  end

  def execute
    is_cancelled = false

    @order.with_lock(timeout: 2, retries: 20, retry_sleep: 0.1) do
      if @order.pending?
        @order.cancel
        is_cancelled = true
      end
    end

    if is_cancelled
      Billing::UpdatePeriod.new(@order.period).execute
      Order::Destroy.immediately(@order.id.to_s)
    end
  end


  def self.immediately(order_id)
    order = Order.where(id: order_id).first

    if order
      order.destroy

      Billing::UpdatePeriod.new(order.period).execute
    end
  end
end
