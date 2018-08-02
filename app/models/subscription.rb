# -*- encoding : UTF-8 -*-
class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization


  has_many :periods
  has_many :documents, class_name: 'PeriodDocument'
  has_many :invoices
  has_and_belongs_to_many :options, class_name: 'SubscriptionOption', inverse_of: :subscribers


  attr_accessor :is_to_apply_now


  validates :number_of_journals, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 10 }


  validates_inclusion_of :period_duration, in: [1, 3, 12]

  def current_period
    find_or_create_period(Date.today)
  end

  def find_period(date)
    periods.where("start_date <= ? AND end_date >= ?", date, date).first
  end

  def create_period(date)
    period = Period.new(start_date: date, duration: period_duration)
    period.subscription = self

    if organization
      period.organization = organization
    else
      period.user = user
    end

    period.save

    UpdatePeriod.new(period).execute

    period
  end

  def find_or_create_period(date)
    find_period(date) || create_period(date)
  end

  def configured?
    is_basic_package_active     ||
    is_micro_package_active     ||
    is_mail_package_active      ||
    is_scan_box_package_active  ||
    is_retriever_package_active ||
    is_annual_package_active    ||
    is_mini_package_active
  end


  def to_be_configured?
    is_basic_package_active     && !is_basic_package_to_be_disabled     ||
    is_micro_package_active     && !is_micro_package_to_be_disabled     ||
    is_mini_package_active      && !is_mini_package_to_be_disabled      ||
    is_mail_package_active      && !is_mail_package_to_be_disabled      ||
    is_scan_box_package_active  && !is_scan_box_package_to_be_disabled  ||
    is_retriever_package_active && !is_retriever_package_to_be_disabled ||
    is_annual_package_active
  end


  def downgrade
    self.is_stamp_active             = false if is_stamp_to_be_disabled
    self.is_mail_package_active      = false if is_mail_package_to_be_disabled
    self.is_basic_package_active     = false if is_basic_package_to_be_disabled
    self.is_micro_package_active     = false if is_micro_package_to_be_disabled
    self.is_mini_package_active      = false if is_mini_package_to_be_disabled
    self.is_pre_assignment_active    = false if is_pre_assignment_to_be_disabled
    self.is_scan_box_package_active  = false if is_scan_box_package_to_be_disabled
    self.is_retriever_package_active = false if is_retriever_package_to_be_disabled
  end


  def light_package?
    !is_annual_package_active
  end

  def heavy_package?
    is_annual_package_active || is_micro_package_active || is_mini_package_active
  end

  def owner
    user || organization
  end

  def set_start_date_and_end_date
    if self.is_micro_package_active || self.is_mini_package_active
      # Updating start_date and end_date when subscription term is reached
      if self.end_date.present? && self.end_date < Date.today
        self.start_date = self.period_duration == 1 ? (self.end_date + 1.day) : (self.end_date + 1.day).beginning_of_quarter
        self.end_date   = self.start_date + 1.year - 1.day
      end
      # When unset
      self.start_date ||= self.period_duration == 1 ? Date.today.beginning_of_month : Date.today.beginning_of_quarter
      self.end_date   ||= self.start_date + 1.year - 1.day

      save
    end
  end

  def current_preceeding_periods
    return [] unless is_micro_package_active
    periods.where("start_date >= ? AND start_date < ?", self.start_date, current_period.start_date)
  end

  def excess_of(value, max_value=nil)
    return 0 unless is_micro_package_active && self.start_date.present? && self.end_date.present? && current_period.start_date.between?(self.start_date, self.end_date)

    max_value ||= "max_#{value.to_s}_authorized"
    current_value        = current_period.send(value.to_sym)
    cumulative_value     = current_preceeding_periods.map(&value.to_sym).sum
    max_authorized_value = self.send(max_value.to_sym)

    if cumulative_value > max_authorized_value
      current_period.send(value.to_sym)
    elsif cumulative_value + current_value > max_authorized_value
      cumulative_value + current_value - max_authorized_value
    else
      0
    end
  end

  def retriever_price_option
    organization_code = organization.try(:code) || user.organization.code
    %w(ADV).include?(organization_code) ? 'reduced_retriever'.to_sym : 'retriever'.to_sym
  end
end
