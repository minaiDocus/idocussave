# -*- encoding : UTF-8 -*-
class ProductOption
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :name,                  type: String,  default: ''
  field :title,                 type: String,  default: ''
  field :description,           type: String,  default: ''
  field :price_in_cents_wo_vat, type: Float,   default: 0.0
  field :position,              type: Integer, default: 1
  field :require_addresses,     type: Boolean, default: false
  field :duration,              type: Integer, default: 1
  field :quantity,              type: Integer, default: 1
  field :action_name
  field :notify,                type: Boolean, default: false
  field :is_default,            type: Boolean, default: false

  validates_presence_of :title, :name, :price_in_cents_wo_vat

  slug :title

  belongs_to :product
  belongs_to :product_group

  scope :default, where: { is_default: true }

public

  class << self
    def by_position
    	asc(:position)
    end

    def by_group
    	asc(:product_group_id)
    end

    def find_by_slug(txt)
      self.first conditions: { slug: txt }
    end
  end

  def first_attribute
    self.name
  end

  def to_a
    [first_attribute, self.price_in_cents_wo_vat]
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.2
  end

  def group_title
    product_group.try(:title) || ""
  end

  def group_position
    product_group.try(:position) || 1
  end
end
