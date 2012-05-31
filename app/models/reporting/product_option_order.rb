class Reporting::ProductOptionOrder
  include Mongoid::Document
  
  field :title, :type => String
  field :group, :type => String
  field :description, :type => String
  field :price_in_cents_wo_vat, :type => Float
  field :position, :type => Integer
  field :require_addresses, :type => Boolean
  field :duration, :type => Integer
  field :quantity, :type => Integer
  
  embedded_in :product_order, :class_name => "Reporting::ProductOrder", :inverse_of => :product_option_orders
  
  class << self
    def by_position
      asc(:position)
    end
  end
  
  # Need for migration
  def group_position
    position
  end
  
  # Need for migration
  def group_title
    group
  end
  
end