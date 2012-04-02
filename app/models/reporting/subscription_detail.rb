class Reporting::SubscriptionDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :monthly, :class_name => "Reporting::Monthly", :inverse_of => :subscription_detail
  embeds_one :product_order, :class_name => "Reporting::ProductOrder", :inverse_of => :subscription_detail
  
  def set_product_order product
    new_product_order = Reporting::ProductOrder.new
    
    new_product_order.title = product.title
    new_product_order.category = product.category
    new_product_order.price_in_cents_wo_vat = product.price_in_cents_wo_vat
    new_product_order.description = product.description
    new_product_order.require_billing_address = product.require_billing_address

    self.product_order = new_product_order
  end
end