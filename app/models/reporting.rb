class Reporting
  include Mongoid::Document
  include Mongoid::Timestamps
  
  references_and_referenced_in_many :viewer, :class_name => "User", :inverse_of => :reportings
  references_many :monthly, :class_name => "Reporting::Monthly", :inverse_of => :reporting
  references_one :customer, :class_name => "Reporting::Customer", :inverse_of => :reporting
  
public
  def find_or_create_monthly_by_date date
    find_or_create_monthly date.year, date.month
  end
  
  def find_or_create_monthly_for year, month
    find_or_create_monthly year, month
  end
  
  def find_or_create_current_monthly
    find_or_create_monthly Time.now.year, Time.now.month
  end
  
  def previous_monthly
    time = Time.now - 1.month
    self.monthly.where(:year => time.year , :month => time.month).first
  end
  
protected
  def find_or_create_monthly year, month
    a_monthly = self.monthly.where(:month => month, :year => year).first
    if a_monthly
      a_monthly
    else
      a_monthly = self.monthly.new
      a_monthly.month = month
      a_monthly.year = year
      if a_monthly.save
        if p_monthly = previous_monthly
          detail = p_monthly.find_or_create_subscription_detail
          unless detail.product_order.nil?
            subscription_detail = a_monthly.find_or_create_subscription_detail
            
            product_order = Reporting::ProductOrder.new
            product_order.fields.keys.each do |k|
              setter =  (k+"=").to_sym
              value = detail.product_order.send(k)
              product_order.send(setter, value)
            end
            subscription_detail.product_order = product_order
            
            subscription_detail.product_order.product_option_orders = []
            
            detail.product_order.product_option_orders.each do |option|
              product_option_order = Reporting::ProductOptionOrder.new
              product_option_order.fields.keys.each do |k|
                setter =  (k+"=").to_sym
                value = option.send(k)
                product_option_order.send(setter, value)
              end
              subscription_detail.product_order.product_option_orders << product_option_order
            end
            a_monthly.save
          end
        end
        a_monthly
      else
        nil
      end
    end
  end
end
