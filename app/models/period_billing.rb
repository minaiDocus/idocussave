# -*- encoding : UTF-8 -*-
class PeriodBilling
  include Mongoid::Document

  embedded_in :period

  field :order,                  type: Integer, default: 1
  field :amount_in_cents_wo_vat, type: Integer, default: 0

  validates_presence_of :order, :amount_in_cents_wo_vat
  validates_inclusion_of :order, in: 1..12
  validate :uniqueness_of_order

private

  def uniqueness_of_order
    billing = period.billings.where(order: order).first
    if billing and billing != self
      errors.add(:order, :taken)
    end
  end
end
