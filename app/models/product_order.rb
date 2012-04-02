class ProductOrder
  include Mongoid::Document
  
  field :title
  field :category, :type => Integer
  field :price_in_cents_wo_vat, :type => Float
  field :description, :type => String
  field :position, :type => Integer
  field :require_billing_address, :type => Boolean, :default => true

  embedded_in :order
  embeds_many :product_option_orders
  
  after_save :update_reporting
  
private
  def update_reporting
    monthly = self.order.user.find_or_create_reporting.find_or_create_monthly_by_date self.order.updated_at
    subscription_detail = monthly.find_or_create_subscription_detail
    subscription_detail.set_product_order self
    monthly.save
  end

end
