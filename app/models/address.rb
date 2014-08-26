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

  embedded_in :locatable, polymorphic: true

  validates_presence_of :first_name, :last_name, unless: Proc.new { |e| e.locatable.try(:class) == ScanningProvider }
  validates_presence_of :city, :zip
  validates_presence_of :address_1, unless: Proc.new { |a| a.address_2.present? }
  validates_presence_of :address_2, unless: Proc.new { |a| a.address_1.present? }

  validates_length_of :first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country, :phone, :phone_mobile, within: 0..50

  scope :for_billing,  where: { is_for_billing: true }
  scope :for_shipping, where: { is_for_shipping: true }

  before_save :set_billing_address, :set_shipping_address

  def name
    [self.first_name, self.last_name].join(' ')
  end

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
      locatable.addresses.each do |address|
        address.is_for_billing = false
      end
      self.is_for_billing = true
    else
      self.is_for_billing = false
    end
    true
  end

  def set_shipping_address
    if self.is_for_shipping.in? ["1", true]
      locatable.addresses.each do |address|
        address.is_for_shipping = false
      end
      self.is_for_shipping = true
    else
      self.is_for_shipping = false
    end
    true
  end

  def info
    [address_1, address_2, zip, city, state].select(&:present?).join(', ')
  end
end
