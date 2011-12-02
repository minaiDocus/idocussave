class ProductOption
  include Mongoid::Document
  include Mongoid::Slug
  
  before_save :create_product_from_attributes
  
  attr_accessor :new_product_title
  attr_accessor :new_product_description
  attr_accessor :new_product_price_in_cents_wo_vat
  attr_accessor :new_product_category
  attr_accessor :new_product_position
  attr_accessor :new_product_duration
  
  field :title
  field :description, :type => String, :default => ""
  field :price_in_cents_wo_vat, :type => Float
  field :position, :type => Integer, :default => 1
  field :require_addresses, :type => Boolean, :default => false
  field :duration, :type => Integer, :default => 1
  field :quantity, :type => Integer, :default => 1
  
  validates_presence_of :title
  validates_presence_of :price_in_cents_wo_vat
  
  slug :title

  referenced_in :product
  referenced_in :group
  
public

  class << self
    def by_position
    	asc(:position)
    end
    
    def by_group
    	asc(:group_id)
    end
    
  end
  
  def self.find_by_slug txt
    self.first :conditions => {:slug => txt}
  end
  
  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
  
protected

  def create_product_from_attributes
  	unless new_product_title.blank? && new_product_description.blank? && new_product_price_in_cents_wo_vat.blank? && new_product_category.blank? && new_product_position.blank? && new_product_duration.blank?
  		document_product = DocumentProduct.new(:title => new_product_title, :description => new_product_description, :price_in_cents_wo_vat => new_product_price_in_cents_wo_vat, :category => new_product_category, :position => new_product_position, :duration => new_product_duration)
      document_product.document_product_options << self
      document_product.save!
  	end
  end
  
end
