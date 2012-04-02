class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  field :category, :type => Integer, :default => 1
  field :progress, :type => Integer, :default => 1
  field :end, :type => Integer, :default => 12
  field :number, :type => Integer
  
  validates_uniqueness_of :number
  
  before_create :set_number
  after_create :create_detail
  
  referenced_in :user
  references_many :orders
  
  references_many :events
  
  references_many :subscription_details, :dependent => :destroy
  
  def order
    orders.current.first
  end
  
  def invalid_current_order
    self.order.update_attributes(:is_curent => false) if self.order
  end
  
  def new_order
    order = Order.new
    order.user = self.user
    order["subscription_id"] = self.id
    order
  end
  
  def detail
    subscription_details.current.first
  end
  
  def claim_money
    self.progress += 1
    # fonction qui débite l'utilisateur en fonction du type de payement
    self.save
  end
  
protected
  def create_detail
    detail = SubscriptionDetail.new
    detail.subscription = self
    detail.save
  end
  
  def set_number
    self.number = DbaSequence.next(:subscription)
  end
end