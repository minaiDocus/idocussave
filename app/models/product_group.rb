# -*- encoding : UTF-8 -*-
class ProductGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :name,                type: String,  default: ''
  field :title,               type: String,  default: ''
  field :position,            type: Integer, default: 1
  field :is_option_dependent, type: Boolean, default: false

  validates_presence_of :name, :title

  slug :name

  has_and_belongs_to_many :products
  has_many :product_options

  has_many   :product_required_for, class_name: 'ProductGroup', inverse_of: :product_require
  belongs_to :product_require,      class_name: 'ProductGroup', inverse_of: :product_required_for

  has_and_belongs_to_many :product_subgroups,   class_name: 'ProductGroup', inverse_of: :product_supergroups
  has_and_belongs_to_many :product_supergroups, class_name: 'ProductGroup', inverse_of: :product_subgroups

  class << self
    def by_position
      asc([:position, :title])
    end

    def find_by_slug(txt)
      self.first conditions: { slug: txt }
    end
  end

  def products_title
    products.map(&:title).join(', ')
  end
end
