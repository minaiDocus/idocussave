class ProductOptionOrder
  include Mongoid::Document
  
  field :title, :type => String
  field :group_title, :type => String
  field :description, :type => String
  field :price_in_cents_wo_vat, :type => Float
  field :position, :type => Integer
  field :duration, :type => Integer
  field :quantity, :type => Integer

  embedded_in :product_optionable, :polymorphic => true
end
