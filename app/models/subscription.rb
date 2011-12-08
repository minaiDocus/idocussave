class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  field :category, :type => Integer, :default => 1
  field :progress, :type => Integer, :default => 1
  field :end, :type => Integer, :default => 12
  field :number, :type => Integer
  
  validates_uniqueness_of :number
  
  before_create :set_number
  
  referenced_in :user
  references_one :order
  
  references_many :events
  
  def claim_money
    self.progress += 1
    # fonction qui débite l'utilisateur en fonction du type de payement
    self.save
  end
  
  def set_number
    self.number = DbaSequence.next(:subscription)
  end
end