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

  validates_length_of :first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country, :phone, :phone_mobile, within: 0..50, allow_nil: true

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
    [company, company_number, first_name, last_name, phone, address_1, zip, city, building, door_code, other].select(&:present?).join(' - ')
  end
end
