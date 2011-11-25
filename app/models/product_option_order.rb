class ProductOptionOrder
  include Mongoid::Document
  
  field :title
  field :description, :type => String
  field :price_in_cents_wo_vat, :type => Float
  field :position, :type => Integer
  field :group, :type => Integer
  field :require_addresses, :type => Boolean
  field :duration, :type => Integer

  embedded_in :product_order
  
end
