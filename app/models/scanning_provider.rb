class ScanningProvider
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  attr_reader :customer_tokens

  field :name, type: String
  field :code, type: String

  slug :name

  validates_presence_of :name
  validates_presence_of :code

  has_many :customers, class_name: 'User', inverse_of: 'scanning_provider'

  embeds_many :addresses, as: :locatable

  accepts_nested_attributes_for :addresses, allow_destroy: true

  def to_s
    self.name
  end

  def customer_tokens=(ids)
    self.customers = User.find(ids.split(','))
  end
end