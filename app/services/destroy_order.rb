# -*- encoding : UTF-8 -*-
class DestroyOrder
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
      UpdatePeriod.new(@order.period).execute
      DestroyOrder.immediately(@order.id.to_s)
    end
  end

  class << self
    def immediately(order_id)
      order = Order.where(id: order_id).first
      if order
        order.destroy
        UpdatePeriod.new(order.period).execute
      end
    end
    handle_asynchronously :immediately, priority: 1, run_at: Proc.new { 30.minutes.from_now }
  end
end
