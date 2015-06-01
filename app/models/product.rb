# -*- encoding : UTF-8 -*-
class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title,           type: String,  default: ''
  field :period_duration, type: Integer, default: 1
  field :position,        type: Integer, default: 1

  validates_presence_of :title

  slug :title

  has_and_belongs_to_many :product_groups
  has_many :product_options

  class << self
    def by_position
      asc(:position)
    end
  end
end
