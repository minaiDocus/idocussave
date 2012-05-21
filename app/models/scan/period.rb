class Scan::Period
  include Mongoid::Document
  include Mongoid::Timestamps
  
  references_many :documents, :class_name => "Scan::Document", :inverse_of => :period
  embeds_many :product_option_orders, :as => :product_optionable
  references_one :invoice, :inverse_of => :period
  embeds_one :delivery, :class_name => "Scan::Delivery", :inverse_of => :period
  
  field :year, :type => Integer, :default => Time.now.year
  field :month, :type => Integer, :default => Time.now.month
  field :duration, :type => Integer, :default => 1
  
  field :price_in_cents_wo_vat, :type => Integer, :default => 0
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
  
  before_create :create_delivery!
  before_save :update_price
  
  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
  
  def update_price!
    update_attributes(:price_in_cents_wo_vat => total_price_in_cent_wo_vat)
  end
  
  def total_price_in_cent_wo_vat
    total = 0
    total += price_of_products
    total += price_of_excess_sheets
    total += price_of_excess_uploaded_pages
    total
  end
  
  def price_of_products
    product_orders.sum(&:price_in_cents_wo_vat)
  end
  
  def price_of_excess_sheets
    excess_sheets = documents.sum(&:sheets) - max_sheets_authorized
    if excess_sheets > 0
      excess_sheets * 12
    else
      0
    end
  end
  
  def price_of_excess_uploaded_pages
    excess_uploaded_pages = documents.sum(&:uploaded_pages) - max_uploaded_pages_authorized
    if excess_uploaded_pages > 0
      (excess_uploaded_pages / 100) * 200 + (excess_uploaded_pages % 100 > 0 ? 200 : 0)
    else
      0
    end
  end
  
  def set_product_orders! products
    products.each do |product|
      new_product_order = product_orders.new
      product.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = product_order.send(k)
        new_product_order.send(setter, value)
      end
      new_product_order.save
    end
  end
  
private
  def attributes_year_and_month_is_uniq
    period = subscription.periods.where(:year => year, :month => month, :duration => duration).first
    if period and period != self
      errors.add(:month, "Period, with year(#{year}) month(#{month}) date, already exist for this customer.")
    else
      true
    end
  end

  def create_delivery!
    self.delivery.create if self.delivery.nil?
  end
end
