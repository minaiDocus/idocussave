# -*- encoding : UTF-8 -*-
class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name
  field :last_name
  field :company
  field :address_1
  field :address_2
  field :city
  field :zip
  field :state
  field :country
  field :phone
  field :phone_mobile
  
  field :is_for_billing,  type: Boolean, default: false
  field :is_for_shipping, type: Boolean, default: false

  embedded_in :user, inverse_of: :addresses

  validates_presence_of :first_name, :last_name, :city, :zip
  validates_presence_of :address_1, unless: Proc.new { |a| a.address_2.present? }
  validates_presence_of :address_2, unless: Proc.new { |a| a.address_1.present? }

  scope :for_billing,  where: { is_for_billing: true }
  scope :for_shipping, where: { is_for_shipping: true }

  before_save :set_billing_address, :set_shipping_address
  
  def as_location
    self.attributes.delete_if { |key, value| key == '_id' }
  end

  def same_location? other
    if other.respond_to? :as_location
      other.as_location == self.as_location
    else
      false
    end
  end

  def set_billing_address
    if self.is_for_billing.in? ["1", true]
      user.addresses.each do |address|
        address.is_for_billing = false
      end
      self.is_for_billing = true
    else
      self.is_for_billing = false
    end
  end

  def set_shipping_address
    if self.is_for_shipping.in? ["1", true]
      user.addresses.each do |address|
        address.is_for_shipping = false
      end
      self.is_for_shipping = true
    else
      self.is_for_shipping = false
    end
  end
end
