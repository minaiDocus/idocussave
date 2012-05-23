class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps
  
  PREPAYED = 1
  DEBIT = 2

  field :category, :type => Integer, :default => 1
  field :start_at, :type => Time, :default => Time.now
  field :end_at, :type => Time, :default => Time.now + 12.month
  field :end_in, :type => Integer, :default => 12 # month
  field :period_duration, :type => Integer, :default => 1
  field :current_progress, :type => Integer, :default => 1
  field :number, :type => Integer
  field :payment_type, :type => Integer, :default => PREPAYED
  field :price_in_cents_wo_vat, :type => Integer, :default => 0
  field :tva_ratio, :type => Float, :default => 1.196
  
  validates_uniqueness_of :number
  
  scope :of_user, lambda { |user| where(:user_id => user.id) }
  scope :for_year, lambda { |year| where(:start_at.lt => Time.local((year + 1),1,1,0,0,0), :end_at.gt => Time.local((year - 1),1,1,0,0,0)) }
  
  before_create :set_number
  before_save :update_price, :set_start_date, :set_end_date
  
  referenced_in :user
  references_many :orders
  references_many :events
  references_many :invoices
  
  # TODO remove me
  references_many :subscription_details, :dependent => :destroy
  
  embeds_many :product_option_orders, :as => :product_optionable
  
  def by_start_date
    asc(:start_at)
  end
  
  def order
    orders.current.first
  end
  
  def invalid_current_order
    self.order.update_attributes(:is_curent => false) if self.order
  end
  
  def new_order
    order = Order.new
    order.user = self.user
    order["subscription_id"] = self.id
    order
  end
  
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
  
  def product= _product
    id = _product[:id]
    product = Product.find id
    _groups = _product[id]
    
    options = []
    option_ids = []
    _groups.each { |key, value| option_ids += value }
    
    _groups.each do |_group|
      group = ProductGroup.find(_group[0])
      required_option = nil
      if group.product_require
        required_option = group.product_require.product_options.any_in(:_id => option_ids).first
      end
      _group[1].each do |option_id|
        option = ProductOption.find option_id
        option_order = copy_product_option(option)
        option_order.price_in_cents_wo_vat = option_order.price_in_cents_wo_vat * required_option.quantity unless required_option.nil?
        options << option_order
      end
    end
    
    self.product_option_orders = options
  end
  
  def copy_product_option product_option
    product_option_order = ProductOptionOrder.new
    product_option_order.fields.keys.each do |k|
      setter =  (k+"=").to_sym
      value = product_option.send(k)
      product_option_order.send(setter, value)
    end
    product_option_order
  end
  
  # TODO remove me
  def detail
    subscription_details.current.first
  end
  
  def claim_money
    self.progress += 1
    # fonction qui débite l'utilisateur en fonction du type de payement
    self.save
  end
  
protected
  def set_number
    self.number = DbaSequence.next(:subscription)
  end
  
  def set_start_date
    year = start_at.year
    month = start_at.month
    if period_duration == 3
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
    self.end_at = start_at + end_in.month - 1.seconds
  end
end