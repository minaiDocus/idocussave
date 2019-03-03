# -*- encoding : UTF-8 -*-
class SubscriptionOption < ApplicationRecord
  has_and_belongs_to_many :subscribers, class_name: 'Subscription', inverse_of: :extra_options


  validates_presence_of  :name, :price_in_cents_wo_vat, :position, :period_duration
  validates_inclusion_of :period_duration, in: [0, 1]

  scope :default,     -> { order(position: :asc)}
  scope :by_position, -> { order(position: :asc) }


  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.2
  end
end
