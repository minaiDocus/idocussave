# -*- encoding : UTF-8 -*-
class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user
  belongs_to :period
  embeds_one :address, as: :locatable

  field :type
  field :price_in_cents_wo_vat, type: Integer
  field :vat_ratio, type: Float, default: 1.2

  field :dematbox_count, type: Integer, default: 0

  field :period_duration,        type: Integer, default: 1
  field :paper_set_casing_size,  type: Integer, default: 0
  field :paper_set_folder_count, type: Integer, default: 0
  field :paper_set_start_date,   type: Date
  field :paper_set_end_date,     type: Date

  validates_inclusion_of :type, in: %w(dematbox paper_set)
  validates_presence_of :price_in_cents_wo_vat
  validates_presence_of :vat_ratio

  validates_inclusion_of :dematbox_count,         in: [1, 2],              if: Proc.new { |o| o.dematbox? }
  validates_presence_of  :address,                                         if: Proc.new { |o| o.dematbox? }

  validates_presence_of  :period_duration,                                 if: Proc.new { |o| o.paper_set? }
  validates_inclusion_of :paper_set_casing_size,  in: [500, 1000, 3000],   if: Proc.new { |o| o.paper_set? }
  validates_inclusion_of :paper_set_folder_count, in: [5, 6, 7, 8, 9, 10], if: Proc.new { |o| o.paper_set? }
  validates_presence_of  :paper_set_start_date,                            if: Proc.new { |o| o.paper_set? }
  validates_presence_of  :paper_set_end_date,                              if: Proc.new { |o| o.paper_set? }

  accepts_nested_attributes_for :address

  def dematbox?
    type == 'dematbox'
  end

  def paper_set?
    type == 'paper_set'
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * vat_ratio
  end
end
