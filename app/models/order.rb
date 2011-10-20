class Order
  # FIXME do that with the builtin i18n rails module
  STATES = [['en panier', 'cart'], ['payée', 'paid'], ['impayée', 'unpaid']]

  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions

  # FIXME use newer syntax
  referenced_in :user
  
  references_many :packs, :dependent => :delete
  
  # DELETE ME AFTER MIGRATION
  references_many :documents
  
  references_one :invoice
	
  embeds_one :product_order
  embeds_one :billing_address, :class_name => 'Address'
  embeds_one :shipping_address, :class_name => 'Address'
  
  field :state, :default => 'cart'
  field :tva_ratio, :type => Float, :default => 1.196
  field :description, :type => String
  field :number, :type => Integer
  field :manual, :type => Boolean, :default => false
  field :waybill_number, :type => String
  field :coliposte, :type => String
  field :document_destiny, :type => Integer, :default => 1

  index :number, :unique => true

  validates_uniqueness_of :number

  before_create :set_number
  before_create :set_waybill_number

  state_machine do
    state :cart
    state :paid
    state :scanned
    state :cancelled

    event :pay do
      transitions :to => :paid, :from => :cart
    end

    event :scanned do
      transitions :to => :scanned, :from => :paid, :on_transition => :do_send_scanned_notification
    end

    event :cancel do
      transitions :to => :cancelled, :from => [:cart, :paid, :scanned]
    end
  end

  def do_send_scanned_notification
    # OrderMailer.scanned_confirmation(self).deliver
  end

  scope :with_state, lambda{|ary| where(:state.in => [ary].flatten.map(&:to_s)) }
  scope :without_state, lambda{|ary| where(:state.nin => [ary].flatten.map(&:to_s)) }

  def total_in_cents_wo_vat
    _product = self.product_order
    
    price =  _product.price_in_cents_wo_vat.to_f rescue -1
    
    _product.product_option_order.each do |option|
      price += option.price_in_cents_wo_vat.to_f rescue -1
    end

    return price
  end

  def total_in_cents_w_vat
    self.total_in_cents_wo_vat * self.tva_ratio
  end


  def total_in_euros_w_vat
    (self.total_in_cents_w_vat / 100).round_at(2)
  end

  def total_vat
    self.total_in_cents_w_vat - self.total_in_cents_wo_vat
  end

  def tax_rate
    (self.tva_ratio - 1) * 100.00
  end

  def waybill_color
    return "C"
  end

  def waybill_post_numerisation
    case self.document_destiny
      when 1 then "R"
      when 2 then "A"
      when 3 then "D"
    end
  end

  def generate_waybill_number
    bits = []
    bits << self.created_at.strftime("%y%m%d")
    bits << self.waybill_color
    bits << self.waybill_post_numerisation
    bits << ("%0.7d" % self.number)
    bits.join()
  end
  
  def original_document
    self.documents.originals.first rescue nil
  end
  
  def set_product_order product, options
    product_order = ProductOrder.new
    product_order.fields.keys.each do |k|
      setter =  (k+"=").to_sym
      value = product.send(k)
      product_order.send(setter, value)
    end

    self.product_order = product_order
    
    options.each do |option|
      product_option_order = ProductOptionOrder.new
      product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = option.send(k)
        product_option_order.send(setter, value)
      end
      self.product_order.product_option_order << product_option_order
    end
  end
  
protected

  def set_number
    self.number = DbaSequence.next(:order)
  end
  
  def set_waybill_number
    self.waybill_number = self.generate_waybill_number
  end

end
