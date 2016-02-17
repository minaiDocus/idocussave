# -*- encoding : UTF-8 -*-
class Order
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Locker

  belongs_to :organization
  belongs_to :user
  belongs_to :period
  embeds_one :address, as: :locatable

  field :state,                 type: String, default: 'pending'
  field :type
  field :price_in_cents_wo_vat, type: Integer
  field :vat_ratio,             type: Float,  default: 1.2

  field :dematbox_count, type: Integer, default: 0

  field :period_duration,        type: Integer, default: 1
  field :paper_set_casing_size,  type: Integer, default: 0
  field :paper_set_folder_count, type: Integer, default: 0
  field :paper_set_start_date,   type: Date
  field :paper_set_end_date,     type: Date

  validates_presence_of :state
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
  validate :inclusion_of_paper_set_start_date,                             if: Proc.new { |o| o.paper_set? }
  validate :inclusion_of_paper_set_end_date,                               if: Proc.new { |o| o.paper_set? }

  accepts_nested_attributes_for :address

  scope :dematboxes, -> { where(type: 'dematbox') }
  scope :paper_sets, -> { where(type: 'paper_set') }

  scope :pending,   -> { where(state: 'pending') }
  scope :confirmed, -> { where(state: 'confirmed') }
  scope :cancelled, -> { where(state: 'cancelled') }

  def dematbox?
    type == 'dematbox'
  end

  def paper_set?
    type == 'paper_set'
  end

  def price_in_cents_w_vat
    price_in_cents_wo_vat * vat_ratio
  end

  state_machine :initial => :pending do
    state :pending
    state :confirmed
    state :cancelled

    event :confirm do
      transition :pending => :confirmed
    end

    event :cancel do
      transition :pending => :cancelled
    end
  end

  def paper_set_start_dates
    date = paper_set_starting_date
    if self.period_duration == 12
      maximum_date = date - 36.months
    else
      maximum_date = date - 12.months
    end
    dates = []
    while date >= maximum_date
      dates << date
      date -= self.period_duration.months
    end
    dates
  end

  def paper_set_end_dates
    date = paper_set_starting_date
    maximum_date = date.end_of_year
    dates = []
    while date <= maximum_date
      dates << date
      date += self.period_duration.months
    end
    dates
  end

private

  def paper_set_starting_date
    start_date = self.created_at.try(:to_date) || Date.today
    case self.period_duration
    when 1
      start_date.beginning_of_month
    when 3
      start_date.beginning_of_quarter
    when 12
      start_date.beginning_of_year
    end
  end

  def inclusion_of_paper_set_start_date
    unless paper_set_start_date.in? paper_set_start_dates
      errors.add(:paper_set_start_date, :invalid)
    end
  end

  def inclusion_of_paper_set_end_date
    unless paper_set_end_date.in? paper_set_end_dates
      errors.add(:paper_set_end_date, :invalid)
    end
  end
end
