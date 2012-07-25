# -*- encoding : UTF-8 -*-
class ProductOptionOrder
  include Mongoid::Document
  
  field :title, :type => String
  field :group_title, :type => String
  field :description, :type => String
  field :price_in_cents_wo_vat, :type => Integer
  field :group_position, :type => Integer
  field :position, :type => Integer
  field :duration, :type => Integer
  field :quantity, :type => Integer

  embedded_in :product_optionable, :polymorphic => true
  
  def self.by_position
    asc([:group_position,:position])
  end
end
