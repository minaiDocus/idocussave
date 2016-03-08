# -*- encoding : UTF-8 -*-
class ConfirmOrder
  class << self
    def execute(object)
      if object.is_a? String
        @order = Order.where(id: object).first
      else
        @order = object
      end
      new(@order).execute if @order
    end
    handle_asynchronously :execute, priority: 1, run_at: Proc.new { 24.hours.from_now + 10.seconds }
  end

  def initialize(order)
    @order = order
  end

  def execute
    is_confirmed = false
    @order.with_lock(timeout: 2, retries: 20, retry_sleep: 0.1) do
      if @order.pending?
        @order.confirm
        is_confirmed = true
      end
    end
    if is_confirmed
      if @order.dematbox?
        OrderMailer.delay(priority: 1).notify_dematbox_order(@order)
      else
        OrderMailer.delay(priority: 1).notify_paper_set_order(@order)
      end
      UpdatePeriod.new(@order.period).execute
    end
  end
end
