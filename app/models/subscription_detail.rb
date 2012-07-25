# -*- encoding : UTF-8 -*-
class SubscriptionDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :current, :type => Boolean, :default => true
  field :base_price_in_cents, :type => Integer, :default => 0
  field :max_number_of_sheets, :type => Integer, :default => 0
  field :max_uploaded_pages, :type => Integer, :default => 0
  
  referenced_in :subscription
  
  scope :current, :where => { :current => true }
  
  before_create :set_current
  
protected
  def set_current
    subscription.subscription_details.current.each do |detail|
      detail.update_attributes(:current => false)
    end
  end
end
