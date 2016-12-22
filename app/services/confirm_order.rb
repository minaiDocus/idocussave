# -*- encoding : UTF-8 -*-
class ConfirmOrder
  def self.execute(object)
    @order = if object.is_a?(String)
                   Order.where(id: object).first
                 else
                   object
                 end

    new(@order).execute if @order
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
        OrderMailer.notify_dematbox_order(@order).deliver_later
      else
        OrderMailer.notify_paper_set_order(@order).deliver_later
      end

      UpdatePeriod.new(@order.period).execute
    end
  end
end
