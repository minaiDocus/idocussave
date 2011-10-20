class ProductOrder
  include Mongoid::Document
  
  field :title
  field :category, :type => Integer
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String
  field :position, :type => Integer

  embedded_in :order,  :inverse_of => :product_order
  embeds_many :product_option_order

end
