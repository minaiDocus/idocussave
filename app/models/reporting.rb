class Reporting
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :client_ids, :type => Array, :default => []
  field :order_ids, :type => Array, :default => []
  
  references_one :user
  
  def clients
    User.any_in(:_id => self.client_ids).entries
  end
  
  def clients= users
    unless users.empty?
      self.client_ids = users.collect{|u| u.id} if users.select{|u| !u.is_a?(User)} == []
    else
      self.client_ids = []
    end
    self.save
    clients
  end
  
  def orders
    Order.any_in(:_id => self.order_ids).entries
  end
  
  def orders= orders
    unless orders.empty?
      self.order_ids = orders.collect{|o| o.id} if orders.select{|o| !o.is_a?(Order)} == []
    else
      self.order_ids = []
    end
    self.save
    orders
  end
  
  def order_add order
    self.order_ids += [order.id]
    self.save
  end
  
  def order_del order
    self.order_ids -= [order.id]
    self.save
  end
  
end
