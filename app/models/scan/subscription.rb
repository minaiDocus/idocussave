# -*- encoding : UTF-8 -*-
class Scan::Subscription < Subscription
  references_many :periods,   class_name: "Scan::Period",   inverse_of: :subscription
  references_many :documents, class_name: "Scan::Document", inverse_of: :subscription
  
  attr_accessor :is_to_spreading, :update_period
  
  field :max_sheets_authorized,       type: Integer, default: 100
  field :max_upload_pages_authorized, type: Integer, default: 200
  
  before_create :set_category, :create_period
  before_save :check_propagation
  before_save :update_current_period, if: Proc.new { |e| e.persisted? }
  
  def set_category
  	self.category = 1
  end
  
  def code
  	self.user.try(:code)
  end
  
  def code=(vcode)
  	self.user = User.where(code: vcode).first
  end

  def find_period(time)
    periods.where(:start_at.lte => time, :end_at.gte => time).first
  end
  
  def _find_period(time)
    periods.select do |period|
      period.start_at < time and period.end_at > time
    end.first
  end
  
  def find_or_create_period(time)
    period = find_period(time)
    if period
      period
    else
      period = Scan::Period.new(start_at: time, duration: period_duration)
      period.subscription = self
      period.user = self.user
      period.set_product_option_orders self.product_option_orders
      period.save
      remove_not_reusable_options
      period
    end
  end
  
  def remove_not_reusable_options
    new_product_option_orders = []
    self.product_option_orders.each do |option|
      new_product_option_orders << option unless option.duration == 0
    end
    self.product_option_orders = new_product_option_orders
  end
  
  def copy!(scan_subscription)
    self.end_in = scan_subscription.end_in
    self.payment_type = scan_subscription.payment_type
    self.period_duration = scan_subscription.period_duration
    self.max_sheets_authorized = scan_subscription.max_sheets_authorized
    self.max_upload_pages_authorized = scan_subscription.max_upload_pages_authorized
    self.copy_options! scan_subscription.product_option_orders
    self.save
  end
  
  def propagate_changes_for(clients)
    clients.each do |client|
      client.find_or_create_scan_subscription.copy! self
    end
  end
  
  def propagate_changes
   propagate_changes_for user.clients.active
  end
  
  def check_propagation
    if is_to_spreading.try(:to_i) == 1 and user.is_prescriber
      propagate_changes
    end
  end

  def create_period
    find_or_create_period(Time.now)
  end

  def update_current_period
    if self.user.is_prescriber
      options = self.product_option_orders.where(:group_position.gte => 1000)
    else
      options = self.product_option_orders
    end
    current_period = find_or_create_period(Time.now)
    current_period.set_product_option_orders(options)
    current_period.save
  end

  def total
    result = 0
    if user.is_prescriber
      subscription_ids = Scan::Subscription.any_in(:user_id => user.clients.map { |e| e.id }).distinct(:_id)
      ps = Scan::Period.any_in(subscription_id: subscription_ids).
           where(:start_at.lt => Time.now, :end_at.gt => Time.now)
      ps.each do |period|
        result += period.total_price_in_cents_wo_vat
      end
      acs = nil
      if(p = find_period(Time.now))
        acs = p
      else
        acs = self
      end
      acs.product_option_orders.where(:group_position.gte => 1000).each do |option|
        result += option.price_in_cents_wo_vat
      end
    else
      result = find_period(Time.now).try(:total_price_in_cents_wo_vat) || 0
    end
    result
  end
  
protected

  def copy_options!(options)
    self.product_option_orders = []
    options.each do |option|
      product_option_order = ProductOptionOrder.new
      product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = option.send(k)
        product_option_order.send(setter, value)
      end
      self.product_option_orders << product_option_order
    end
  end
end
