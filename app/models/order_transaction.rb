class OrderTransaction
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, :type => Integer
  field :success, :type => Boolean
  field :reference
  field :message
  field :actions
  field :params
  field :test, :type => Boolean

  belongs_to_related :document_order
  
  before_create :set_reference
  
  def set_reference
    self.reference = DbaSequence.next(:order_transaction)
  end
  
  def self.find_by_reference txt
    self.last :conditions => {:reference => txt}
  end
end
