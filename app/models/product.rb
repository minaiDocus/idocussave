# -*- encoding : UTF-8 -*-
class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title
  field :category,                type: Integer, default: 1
  field :price_in_cents_wo_vat,   type: Integer, default: 0
  field :description,             type: String,  default: ''
  field :period_duration,         type: Integer, default: 1
  field :position,                type: Integer, default: 1
  field :is_a_subscription,       type: Boolean, default: false
  field :require_billing_address, type: Boolean, default: true
  field :header_info,             type: String,  default: ''
  field :footer_info,             type: String,  default: ''

  validates_presence_of :title, :price_in_cents_wo_vat

  slug :title

  has_and_belongs_to_many :product_groups
  has_many :product_options
  
  scope :subscribable,   where: { is_a_subscription: true }
  scope :unsubscribable, where: { is_a_subscription: false }

  class << self
    def by_price_ascending
      asc(:price_in_cents_wo_vat)
    end
    
    def by_position
      asc(:position)
    end

    def find_by_slug(txt)
      self.first conditions: { slug: txt }
    end
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.2
  end
end
