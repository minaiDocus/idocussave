# -*- encoding : UTF-8 -*-
class ProductOption
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  field :title
  field :description,           type: String,  default: ""
  field :price_in_cents_wo_vat, type: Float
  field :position,              type: Integer, default: 1
  field :require_addresses,     type: Boolean, default: false
  field :duration,              type: Integer, default: 1
  field :quantity,              type: Integer, default: 1
  
  validates_presence_of :title, :price_in_cents_wo_vat
  
  slug :title

  referenced_in :product
  referenced_in :product_group
  
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

  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
  
  def group_title
    product_group.try(:title) || ""
  end
  
  def group_position
    product_group.try(:position) || 1
  end
end
