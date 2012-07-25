# -*- encoding : UTF-8 -*-
class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name
  field :last_name
  field :company
  field :address_1
  field :address_2
  field :address_3
  field :city
  field :zip
  field :state
  field :country
  field :phone
  field :phone_mobile
  
  field :is_for_billing, :type => Boolean, :default => false
  field :is_for_shipping, :type => Boolean, :default => false

  embedded_in :user,  :inverse_of => :addresses

  embedded_in :order, :inverse_of => :shipping_address
  embedded_in :order, :inverse_of => :billing_address

  validates_presence_of :first_name, :last_name, :address_2, :city, :zip
  
  scope :for_billing, :where => { :is_for_billing => true }
  scope :for_shipping, :where => { :is_for_shipping => true }
  
  def as_location
    self.attributes.delete_if {|key, value| key == '_id' } 
  end

  def same_location? other
    if other.respond_to? :as_location
      other.as_location == self.as_location
    else
      false
    end
    
  end
end
