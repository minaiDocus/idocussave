# -*- encoding : UTF-8 -*-
class ProductOptionOrder
  include Mongoid::Document
  
  field :title,                 type: String
  field :group_title,           type: String
  field :description,           type: String
  field :price_in_cents_wo_vat, type: Integer
  field :group_position,        type: Integer
  field :position,              type: Integer
  field :duration,              type: Integer
  field :quantity,              type: Integer

  embedded_in :product_optionable, polymorphic: true

  scope :usable, not_in: { position: [-1] }
  scope :user_editable, where: { :group_position.lt => 1000 }
  
  def self.by_position
    asc([:group_position,:position])
  end
  
  def ==(product_option_order)
    result = true
    result = false unless self.title == product_option_order.title
    result = false unless self.group_title == product_option_order.group_title 
    result = false unless self.description == product_option_order.description 
    result = false unless self.price_in_cents_wo_vat == product_option_order.price_in_cents_wo_vat 
    result = false unless self.group_position == product_option_order.group_position 
    result = false unless self.position == product_option_order.position
    result = false unless self.duration == product_option_order.duration
    result = false unless self.quantity == product_option_order.quantity
    result
  end

  def eql?(product_option_order)
    self == product_option_order
  end
end
