class ProductOption
  include Mongoid::Document
  include Mongoid::Slug
  
  before_save :create_product_from_attributes
  
  attr_accessor :new_product_title
  attr_accessor :new_product_description
  attr_accessor :new_product_price_in_cents_wo_vat
  attr_accessor :new_product_category
  attr_accessor :new_product_position
  
  field :title
  field :description, :type => String, :default => ""
  field :price_in_cents_wo_vat, :type => Float
  field :position, :type => Integer, :default => 1
  field :group, :type => Integer, :default => 1
  field :require_addresses, :type => Boolean, :default => false
  field :is_a_subscription, :type => Boolean, :default => false
  field :begin, :type => Date
  field :end, :type => Date
  
  validates_presence_of :title
  validates_presence_of :price_in_cents_wo_vat
  
  slug :title

  referenced_in :product
  
  class << self
    def by_position
    	asc(:group).asc(:position)
    end
  end
  
  def create_product_from_attributes
  	unless new_product_title.blank? && new_product_description.blank? && new_product_price_in_cents_wo_vat.blank? && new_product_category.blank? && new_product_position.blank?
  		document_product = DocumentProduct.new(:title => new_product_title, :description => new_product_description, :price_in_cents_wo_vat => new_product_price_in_cents_wo_vat, :category => new_product_category, :position => new_product_position)
      document_product.document_product_options << self
      document_product.save!
  	end
  end
  
  def self.find_by_slug txt
    self.first :conditions => {:slug => txt}
  end
  
  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
  
end
