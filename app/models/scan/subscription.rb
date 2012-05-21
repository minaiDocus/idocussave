class Scan::Subscription < Subscription
  referenced_in :prescriber, :class_name => "User", :inverse_of => :scan_subscription_reports
  references_many :periods, :class_name => "Scan::Period", :inverse_of => :subscription
  references_many :documents, :class_name => "Scan::Document", :inverse_of => :subscription
  
  attr_accessor :is_to_spreading
  
  field :period_duration, :type => Integer, :default => 1
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
  
  def find_or_create_period_by time
    find_or_create_period time.year, time.month
  end
  
  def find_or_create_period year, month, duration=nil
    ecart = duration.nil? ? period_duration : duration
    period = periods.where(:year => year, :month.lt => month + 1, :month.gt => month - ecart, :duration => duration).last
    if period
      period
    else
      period = periods.create(:year => year, :month => month, :duration => duration)
      period.set_product_orders! product_orders
      period
    end
  end
  
  def copy! scan_subscription
    self.end_in = scan_subscription.end_in
    self.payment_type = scan_subscription.payment_type
    self.period_duration = scan_subscription.period_duration
    self.max_sheets_authorized = scan_subscription.max_sheets_authorized
    self.max_upload_pages_authorized = scan_subscription.max_upload_pages_authorized
    self.product_option_orders = scan_subscription.product_option_orders
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
end