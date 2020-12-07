# -*- encoding : UTF-8 -*-
class Order < ApplicationRecord
  attr_accessor :address_required
  self.inheritance_column = :_type_disabled

  has_one :address, as: :locatable, :dependent => :destroy
  has_one :paper_return_address, as: :locatable, class_name: 'Address', :dependent => :destroy
  has_one :kit, -> { where type: 'kit' }, class_name: 'PaperProcess', :dependent => :destroy

  belongs_to :user, optional: true
  belongs_to :period, optional: true
  belongs_to :organization, optional: true

  validate :inclusion_of_paper_set_end_date,   if: proc { |o| o.paper_set? }
  validate :inclusion_of_paper_set_start_date, if: proc { |o| o.paper_set? }
  validate :value_of_paper_set_start_date,     if: proc { |o| o.paper_set? }

  validates_presence_of  :state
  validates_presence_of  :address,              if: proc { |o| o.address_required? }
  validates_presence_of  :vat_ratio
  validates_presence_of  :period_duration,      if: proc { |o| o.paper_set? }
  validates_presence_of  :paper_set_casing_count, if: proc { |o| o.paper_set? }
  validates_presence_of  :paper_set_end_date,   if: proc { |o| o.paper_set? }
  validates_presence_of  :paper_return_address, if: proc { |o| o.paper_set? && o.address_required? }
  validates_presence_of  :paper_set_start_date, if: proc { |o| o.paper_set? }
  validates_presence_of  :price_in_cents_wo_vat

  validates_inclusion_of :type, in: %w(dematbox paper_set)
  validates_inclusion_of :dematbox_count, in: [1, 2, 10], if: proc { |o| o.dematbox? }
  validates_inclusion_of :paper_set_casing_size,  in: [500, 1000, 3000],   if: proc { |o| o.paper_set? }
  validates_inclusion_of :paper_set_folder_count, in: [5, 6, 7, 8, 9, 10], if: proc { |o| o.paper_set? }


  accepts_nested_attributes_for :address, :paper_return_address, allow_destroy: true


  scope :pending,    -> { where(state: 'pending') }
  scope :confirmed,  -> { where(state: 'confirmed') }
  scope :cancelled,  -> { where(state: 'cancelled') }
  scope :billed,     -> { where(state: ['confirmed','processed']) }
  scope :dematboxes, -> { where(type: 'dematbox') }
  scope :paper_sets, -> { where(type: 'paper_set') }



  state_machine initial: :pending do
    state :pending
    state :confirmed
    state :cancelled
    state :processed

    event :confirm do
      transition pending: :confirmed
    end

    event :cancel do
      transition pending: :cancelled
    end

    event :process do
      transition confirmed: :processed
    end

  end


  def dematbox?
    type == 'dematbox'
  end


  def paper_set?
    type == 'paper_set'
  end


  def price_in_cents_w_vat
    price_in_cents_wo_vat * vat_ratio
  end


  def paper_set_start_dates
    date = paper_set_starting_date

    maximum_date = if period_duration == 12
                     (date - 36.months).beginning_of_year
                   else
                     (date - 12.months).beginning_of_year
                   end
    dates = []

    while date >= maximum_date
      dates << date

      date -= period_duration.months
    end

    dates
  end

  def paper_set_annual_end_date
    time = (Date.today.month < 12 ? Time.now.end_of_year : 1.month.from_now.end_of_year)
    time = case self.user.subscription.period_duration
    when 1
      time.beginning_of_month
    when 3
      time.beginning_of_quarter
    when 12
      time.beginning_of_year
    end rescue Time.now
    self.paper_set_end_date   = time.to_date
  end


  def paper_set_end_dates
    date = paper_set_starting_date

    maximum_date = date.end_of_year

    dates = paper_set_start_dates.sort

    while date <= maximum_date
      dates << date
      date += period_duration.months
    end
    dates.uniq.reverse
  end


  def self.search(contains)
    orders   = Order.all
    user_ids = []

    if contains[:user_code].present?
      user_ids = User.where("code LIKE ?", "%#{contains[:user_code]}%").pluck(:id)
    end

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        orders = orders.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:price_in_cents_wo_vat]
      contains[:price_in_cents_wo_vat].each do |operator, value|
        orders = orders.where("price_in_cents_wo_vat #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    orders = orders.where(type:    contains[:type])  if contains[:type].present?
    orders = orders.where(state:   contains[:state]) if contains[:state].present?
    orders = orders.where(user_id: user_ids)         if user_ids.any?

    orders
  end

  def self.search_for_collection(collection, contains)
    return collection if collection.empty?
    user_ids = []
    _ids = []


    if contains[:user_code].present?
      user_ids += User.where("code LIKE ?", "%#{contains[:user_code]}%").pluck(:id)
    end

    if contains[:company].present?
      user_ids += User.where("company LIKE ?", "%#{contains[:company]}%").pluck(:id)
    end

    if contains[:tracking_number].present?
      _ids = PaperProcess.kits.where("tracking_number LIKE ?", "%#{contains[:tracking_number]}%").pluck(:order_id)
    end

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        collection = collection.where("orders.created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    collection = collection.where(id: _ids)                  if _ids.any?
    collection = collection.where(state:   contains[:state]) if contains[:state].present?
    collection = collection.where(user_id: user_ids.uniq)    if user_ids.any?

    collection
  end

  def address_required?
    address_required.nil? ? true : address_required
  end

  private

  def paper_set_starting_date
    #Order paper set for the new year is only available from the 1th of december (it was 15th of december before)
    start_date = (Date.today.day >= 1 && Date.today.month == 12) ? 1.month.from_now.to_date : Date.today

    case period_duration
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

  def value_of_paper_set_start_date
    unless paper_set_start_date <= paper_set_end_date
      errors.add(:paper_set_start_date, :invalid)
    end
  end
end
