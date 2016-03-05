# -*- encoding : UTF-8 -*-
class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name
  field :last_name
  field :email
  field :company
  field :company_number
  field :address_1
  field :address_2
  field :city
  field :zip
  field :state
  field :country
  field :building
  field :place_called_or_postal_box
  field :door_code
  field :other
  field :phone
  field :phone_mobile

  field :is_for_billing,            type: Boolean, default: false
  field :is_for_paper_return,       type: Boolean, default: false
  field :is_for_paper_set_shipping, type: Boolean, default: false
  field :is_for_dematbox_shipping,  type: Boolean, default: false

  embedded_in :locatable, polymorphic: true

  validates_presence_of :first_name, :last_name, unless: Proc.new { |e| e.locatable.try(:class) == ScanningProvider }
  validates_presence_of :city, :zip
  validates_presence_of :address_1, unless: Proc.new { |a| a.address_2.present? }
  validates_presence_of :address_2, unless: Proc.new { |a| a.address_1.present? }
  validates_presence_of :company, :company_number, :phone, if: Proc.new { |a| a.is_for_dematbox_shipping }

  validates_length_of :first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country, :building, :place_called_or_postal_box, :door_code, :other, :phone, :phone_mobile, within: 0..50, allow_nil: true

  scope :for_billing,            -> { where(is_for_billing:            true) }
  scope :for_paper_return,       -> { where(is_for_paper_return:       true) }
  scope :for_paper_set_shipping, -> { where(is_for_paper_set_shipping: true) }
  scope :for_dematbox_shipping,  -> { where(is_for_dematbox_shipping:  true) }

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

  def info
    [address_1, address_2, zip, city, state].select(&:present?).join(', ')
  end

  def long_info
    [company, company_number, first_name, last_name, phone, address_1, place_called_or_postal_box, zip, city, building, door_code, other].select(&:present?).join(' - ')
  end

  def copy(address)
    self.first_name                 = address.first_name
    self.last_name                  = address.last_name
    self.email                      = address.email
    self.company                    = address.company
    self.company_number             = address.company_number
    self.address_1                  = address.address_1
    self.address_2                  = address.address_2
    self.city                       = address.city
    self.zip                        = address.zip
    self.state                      = address.state
    self.country                    = address.country
    self.building                   = address.building
    self.place_called_or_postal_box = address.place_called_or_postal_box
    self.door_code                  = address.door_code
    self.other                      = address.other
    self.phone                      = address.phone
    self.phone_mobile               = address.phone_mobile
  end
end
