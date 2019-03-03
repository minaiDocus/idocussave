class ScanningProvider < ApplicationRecord
  attr_reader :customer_tokens

  validates_presence_of :name
  validates_presence_of :code

  has_many :customers, class_name: 'User', inverse_of: 'scanning_provider'
  has_many :addresses, as: :locatable

  accepts_nested_attributes_for :addresses, allow_destroy: true

  scope :default, -> { where(is_default: true) }


  def to_s
    name
  end


  def customer_tokens=(ids)
    self.customers = User.find(ids.split(','))
  end
end
