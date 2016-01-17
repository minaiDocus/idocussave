# -*- encoding : UTF-8 -*-
class SubscriptionOption
  include Mongoid::Document
  include Mongoid::Timestamps

  has_and_belongs_to_many :subscribers, class_name: 'Subscription', inverse_of: :extra_options

  field :name,                  type: String
  field :price_in_cents_wo_vat, type: Integer, default: 0
  field :position,              type: Integer, default: 1
  field :period_duration,       type: Integer, default: 1

  validates_presence_of :name, :price_in_cents_wo_vat, :position, :period_duration

  scope :default, -> { asc(:position) }

  class << self
    def by_position
      asc(:position)
    end
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.2
  end
end
