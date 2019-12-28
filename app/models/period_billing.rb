# -*- encoding : UTF-8 -*-
class PeriodBilling < ApplicationRecord
  belongs_to :period

  validate :uniqueness_of_order
  validates_presence_of  :order, :amount_in_cents_wo_vat, :excesses_amount_in_cents_wo_vat
  validates_inclusion_of :order, in: 1..12

  def pieces
    scanned_pieces + uploaded_pieces + dematbox_scanned_pieces + retrieved_pieces
  end

  def pages
    scanned_pages + uploaded_pages + dematbox_scanned_pages + retrieved_pages
  end

  def compta_pieces
    preseizure_pieces + expense_pieces
  end

private

  def uniqueness_of_order
    billing = period.billings.where(order: order).first
    errors.add(:order, :taken) if billing && billing != self
  end
end
