# -*- encoding : UTF-8 -*-
class Credit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions
  
  after_create :set_number

  field :amount, :type => Integer
  field :number, :type => String
  field :payment_type, :type => String
  field :params
  field :state, :default => 'unpaid'
  
  index :number, :unique => true

  referenced_in :user
  
  state_machine do
    state :unpaid
    state :paid
    state :canceled
    state :credited

    event :pay do
      transitions :to => :paid, :from => [:unpaid,:canceled]
    end
    
    event :cancel do
      transitions :to => :canceled, :from => :unpaid
    end
    
    event :credit do
      transitions :to => :credited, :from => :paid
    end
    
  end
  
  def self.find_number param
    self.first :conditions => {:number => param}
  end
  
  def set_number
    self.number = "CREDIT#{DbaSequence.next(:credit)}"
    self.save!
    
  end
  
  def set_pay
    if self.pay!
      self.user.update_attribute(:balance_in_cents,self.user.balance_in_cents+self.amount)
      self.credit!
    end

  end
  
end
