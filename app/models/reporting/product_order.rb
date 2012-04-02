class Reporting::ProductOrder
  include Mongoid::Document
  
  field :title
  field :category, :type => Integer
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String
  field :require_billing_address, :type => Boolean, :default => true
  
  embedded_in :subscription_detail, :class_name => "Reporting::SubscriptionDetail", :inverse_of => :product_order
  embeds_many :product_option_orders, :class_name => "Reporting::ProductOptionOrder", :inverse_of => :product_order
  
  def set_product_option_order options
    self.product_option_orders = []
    options.each do |option|      
      product_option_order = Reporting::ProductOptionOrder.new
      
      product_option_order.title = option.title
      product_option_order.group = option.group
      product_option_order.price_in_cents_wo_vat = option.price_in_cents_wo_vat
      product_option_order.position = option.position
      product_option_order.duration = option.duration
      product_option_order.quantity = option.quantity
      product_option_order.require_addresses = option.require_addresses
      
      self.product_option_orders << product_option_order
    end
  end
  
end