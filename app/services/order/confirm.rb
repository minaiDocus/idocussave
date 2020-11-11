# -*- encoding : UTF-8 -*-
class Order::Confirm
  def self.execute(object)
    @order = if object.is_a?(Integer)
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

    @order.with_lock do
      if @order.pending?
        is_confirmed =  @order.confirm
      end
    end

    if is_confirmed
      if @order.dematbox?
        OrderMailer.notify_dematbox_order(@order).deliver_later
      else
        OrderMailer.notify_paper_set_order(@order).deliver_later
      end

      Billing::UpdatePeriod.new(@order.period).execute
    elsif @order.errors[:address].any? && @order.type == 'paper_set'
      @order.organization.admins.each do |admin|
        OrderMailer.notify_paper_set_reminder(@order, admin.email).deliver_later
      end
      Order::Confirm.delay_for(24.hours).execute(@order.id)
    end
  end
end
