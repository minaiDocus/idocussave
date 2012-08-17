# -*- encoding : UTF-8 -*-
class ProductGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :name, :type => String
  field :title, :type => String
  field :description, :type => String, :default => ""
  field :position, :type => Integer, :default => 1
  field :is_option_dependent, :type => Boolean, :default => false
  
  validates_presence_of :title
  validates_presence_of :name
  
  slug :name
  
  referenced_in :product
  references_many :product_options
  
  references_many :product_required_for, :class_name => 'ProductGroup', :inverse_of => :product_require
  referenced_in :product_require, :class_name => 'ProductGroup', :inverse_of => :product_required_for
  
  references_many :product_subgroups, :class_name => 'ProductGroup', :inverse_of => :product_supergroup
  referenced_in :product_supergroup, :class_name => 'ProductGroup', :inverse_of => :product_subgroups
  
  class << self
    def by_position
      asc([:position,:title])
    end

    def find_by_slug(txt)
      self.first conditions: { slug: txt }
    end
  end
end
