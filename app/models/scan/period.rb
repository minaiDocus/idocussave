class Scan::Period
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user, :inverse_of => :periods
  referenced_in :subscription, :class_name => "Scan::Subscription", :inverse_of => :periods
  references_many :documents, :class_name => "Scan::Document", :inverse_of => :period
  embeds_many :product_option_orders, :as => :product_optionable
  references_one :invoice, :inverse_of => :period
  embeds_one :delivery, :class_name => "Scan::Delivery", :inverse_of => :period
  
  field :start_at, :type => Time, :default => Time.local(Time.now.year,Time.now.month,1,0,0,0)
  field :end_at, :type => Time, :default => Time.local(Time.now.year + 1,Time.now.month,1,0,0,0)
  field :duration, :type => Integer, :default => 1
  
  field :price_in_cents_wo_vat, :type => Integer, :default => 0
  field :tva_ratio, :type => Float, :default => 1.196
  field :max_sheets_authorized, :type => Integer, :default => 100
  field :max_upload_pages_authorized, :type => Integer, :default => 200
  
  field :pages, :type => Integer, :default => 0
  field :sheets, :type => Integer, :default => 0
  field :pieces, :type => Integer, :default => 0
  field :uploaded_pages, :type => Integer, :default => 0
  field :uploaded_sheets, :type => Integer, :default => 0
  field :uploaded_pieces, :type => Integer, :default => 0
  field :oversized, :type => Integer, :default => 0
  field :paperclip, :type => Integer, :default => 0
  
  scope :monthly, :where => { :duration => 1 }
  scope :bimonthly, :where => { :duration => 2 }
  scope :quarterly, :where => { :duration => 3 }
  scope :annual, :where => { :duration => 12 }
  
  validate :attributes_year_and_month_is_uniq
  
  before_create :add_one_delivery!
  before_save :update_price, :set_start_date, :set_end_date
  
  def price_in_cents_w_vat
    price_in_cents_wo_vat * tva_ratio
  end
  
  def total_vat
    price_in_cents_w_vat - price_in_cents_wo_vat
  end
  
  def update_price
    self.price_in_cents_wo_vat = products_total_price_in_cents_wo_vat
  end
  
  def update_price!
    update_attributes(:price_in_cents_wo_vat => products_total_price_in_cents_wo_vat)
  end
  
  def products_total_price_in_cents_wo_vat
    product_option_orders.sum(&:price_in_cents_wo_vat)
  end
  
  def products_total_price_in_cents_w_vat
    products_total_price_in_cents_wo_vat * tva_ratio
  end
  
  def price_of_excess_uploaded_pages
    excess_uploaded_pages = documents.sum(&:uploaded_pages) - max_uploaded_pages_authorized
    if excess_uploaded_pages > 0
      (excess_uploaded_pages / 100) * 200 + (excess_uploaded_pages % 100 > 0 ? 200 : 0)
    else
      0
    end
  end
  
  def set_product_option_orders product_options
    product_options.each do |product_option|
      new_product_option_order = product_option_orders.new
      new_product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = product_option.send(k)
        new_product_option_order.send(setter, value)
      end
      new_product_option_order.save
    end
  end
  
private
  def attributes_year_and_month_is_uniq
    period = subscription.periods.where(:start_at.gt => start_at - 1.days, :end_at.lt => end_at + 1.days, :duration => duration).first
    if period and period != self
      errors.add(:month, "Period, with start_at '#{start_at}' and end_at '#{end_at}', already exist for this customer.")
    else
      true
    end
  end
  
  def set_start_date
    year = start_at.year
    month = start_at.month
    if duration == 3
      if start_at.month <= 3
        month = 1
      elsif start_at.month <= 6
        month = 4
      elsif start_at.month <= 9
        month = 7
      elsif start_at.month <= 12
        month = 10
      end
    end
    self.start_at = Time.local year,month,1,0,0,0
  end
  
  def set_end_date
    self.end_at = start_at + duration.month - 1.seconds
  end

  def add_one_delivery!
    self.delivery = Scan::Delivery.new
  end
end
