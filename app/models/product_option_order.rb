class ProductOptionOrder
  include Mongoid::Document
  
  field :title
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String
  field :position, :type => Integer
  field :group, :type => Integer
  field :require_addresses, :type => Boolean

  embedded_in :product_order
  
end
