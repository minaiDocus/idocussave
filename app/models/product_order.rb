class ProductOrder
  include Mongoid::Document
  
  field :title
  field :category, :type => Integer
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String
  field :position, :type => Integer
  field :require_billing_address, :type => Boolean, :default => true

  embedded_in :order
  # embeds_many :product_option_orders
end
