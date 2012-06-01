class Scan::Subscription < Subscription
  referenced_in :prescriber, :class_name => "User", :inverse_of => :scan_subscription_reports
  references_many :periods, :class_name => "Scan::Period", :inverse_of => :subscription
  references_many :documents, :class_name => "Scan::Document", :inverse_of => :subscription
  
  attr_accessor :is_to_spreading
  
  field :max_sheets_authorized, :type => Integer, :default => 100
  field :max_upload_pages_authorized, :type => Integer, :default => 200
  
  validates_presence_of :prescriber_id
  
  before_create :set_category
  after_save :check_propagation
  
  def set_category
  	category = 1
  end
  
  def code
  	self.user.try(:code)
  end
  
  def code= vcode
  	self.user = User.where(:code => vcode).first
  end
  
  def prescriber_code
  	self.prescriber.try(:code)
  end
  
  def prescriber_code= vcode
  	self.prescriber = User.where(:code => vcode).first
  end
  
  def find_period time
    periods.where(:start_at.lt => time, :end_at.gt => time, :duration => period_duration).first
  end
  
  def _find_period time
    periods.select do |period|
      period.start_at < time and
      period.end_at > time and
      period.duration == period_duration
    end.first
  end
  
  def find_or_create_period time
    period = find_period time
    if period
      period
    else
      period = Scan::Period.new(:start_at => time, :duration => period_duration)
      period.subscription = self
      period.user = self.user
      period.set_product_option_orders self.product_option_orders
      period.save
      period
    end
  end
  
  def copy! scan_subscription
    self.end_in = scan_subscription.end_in
    self.payment_type = scan_subscription.payment_type
    self.period_duration = scan_subscription.period_duration
    self.max_sheets_authorized = scan_subscription.max_sheets_authorized
    self.max_upload_pages_authorized = scan_subscription.max_upload_pages_authorized
    self.copy_options! scan_subscription.product_option_orders
    self.save
  end
  
  def propagate_changes_for clients
    clients.each do |client|
      client.find_or_create_scan_subscription.copy! self
    end
  end
  
  def propagate_changes
   propagate_changes_for user.clients
  end
  
  def check_propagation
    if is_to_spreading.try(:to_i) == 1 and user.is_prescriber
      propagate_changes
    end
  end
  
protected
  def copy_options! options
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