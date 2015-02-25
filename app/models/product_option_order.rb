# -*- encoding : UTF-8 -*-
class ProductOptionOrder
  include Mongoid::Document

  field :name
  field :title
  field :group_title
  field :description
  field :price_in_cents_wo_vat, type: Float
  field :group_position,        type: Integer
  field :position,              type: Integer
  field :duration,              type: Integer
  field :quantity,              type: Integer
  field :action_name
  field :notify

  embedded_in :product_optionable, polymorphic: true

  scope :usable, not_in: { position: [-1] }
  scope :user_editable, where: { :group_position.lt => 1000 }

  def self.by_position
    asc([:group_position,:position])
  end

  def ==(product_option_order)
    result = true
    result = false unless self.name                  == product_option_order.name
    result = false unless self.title                 == product_option_order.title
    result = false unless self.group_title           == product_option_order.group_title
    result = false unless self.description           == product_option_order.description
    result = false unless self.price_in_cents_wo_vat == product_option_order.price_in_cents_wo_vat
    result = false unless self.duration              == product_option_order.duration
    result = false unless self.quantity              == product_option_order.quantity
    result = false unless self.action_name           == product_option_order.action_name
    result = false unless self.notify                == product_option_order.notify
    result
  end

  def eql?(product_option_order)
    self == product_option_order
  end

  def to_a
    [self.name, self.price_in_cents_wo_vat]
  end
end
