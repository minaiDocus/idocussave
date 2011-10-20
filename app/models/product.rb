class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title
  field :category, :type => Integer, :default => 1
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String, :default => ""
  field :position, :type => Integer, :default => 1

  validates_presence_of :title
  validates_presence_of :price_in_cents_wo_vat

  slug :title
  
  references_many :product_options, :dependent => :delete

  class << self
    def by_price_ascending
      order_by(:price_in_cents_wo_vat.asc)
    end
    
    def  by_position
      asc(:position)
    end
  end
  
  def self.find_by_slug txt
    self.first :conditions => {:slug => txt}
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
  
end
