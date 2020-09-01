# -*- encoding : UTF-8 -*-
class ProductOptionOrder < ApplicationRecord
  belongs_to :product_optionable, polymorphic: true

  scope :by_position, -> { order(group_position: :asc, position: :asc) }
  scope :is_not_frozen,  -> { where(is_frozen: false) }
  scope :is_frozen,      -> { where(is_frozen: true) }


  def ==(product_option_order)
    result = true
    result = false unless name                  == product_option_order.name
    result = false unless title                 == product_option_order.title
    result = false unless group_title           == product_option_order.group_title
    result = false unless description           == product_option_order.description
    result = false unless price_in_cents_wo_vat == product_option_order.price_in_cents_wo_vat
    result = false unless duration              == product_option_order.duration
    result = false unless quantity              == product_option_order.quantity
    result = false unless is_an_extra           == product_option_order.is_an_extra
    result
  end


  def eql?(product_option_order)
    self == product_option_order
  end
end
