# -*- encoding : UTF-8 -*-
class PeriodBilling
  include Mongoid::Document

  embedded_in :period

  field :order,                           type: Integer, default: 1
  field :amount_in_cents_wo_vat,          type: Integer, default: 0
  field :excesses_amount_in_cents_wo_vat, type: Integer, default: 0

  field :scanned_pieces,          type: Integer, default: 0
  field :scanned_sheets,          type: Integer, default: 0
  field :scanned_pages,           type: Integer, default: 0
  field :dematbox_scanned_pieces, type: Integer, default: 0
  field :dematbox_scanned_pages,  type: Integer, default: 0
  field :uploaded_pieces,         type: Integer, default: 0
  field :uploaded_pages,          type: Integer, default: 0
  field :fiduceo_pieces,          type: Integer, default: 0
  field :fiduceo_pages,           type: Integer, default: 0
  field :preseizure_pieces,       type: Integer, default: 0
  field :expense_pieces,          type: Integer, default: 0
  field :paperclips,              type: Integer, default: 0
  field :oversized,               type: Integer, default: 0

  field :excess_sheets,                 type: Integer, default: 0
  field :excess_uploaded_pages,         type: Integer, default: 0
  field :excess_dematbox_scanned_pages, type: Integer, default: 0
  field :excess_compta_pieces,          type: Integer, default: 0

  validates_presence_of :order, :amount_in_cents_wo_vat, :excesses_amount_in_cents_wo_vat
  validates_inclusion_of :order, in: 1..12
  validate :uniqueness_of_order

  def compta_pieces
    preseizure_pieces + expense_pieces
  end

private

  def uniqueness_of_order
    billing = period.billings.where(order: order).first
    if billing and billing != self
      errors.add(:order, :taken)
    end
  end
end
