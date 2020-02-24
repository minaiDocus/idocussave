# -*- encoding : UTF-8 -*-
class Subscription < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true


  has_many :periods
  has_many :documents, class_name: 'PeriodDocument'
  has_many :invoices
  has_and_belongs_to_many :options, class_name: 'SubscriptionOption', inverse_of: :subscribers


  attr_accessor :is_to_apply_now


  validates :number_of_journals, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 12 }


  validates_inclusion_of :period_duration, in: [1, 12]

  def current_period
    find_or_create_period(Date.today)
  end

  def find_period(date)
    periods.where("start_date <= ? AND end_date >= ?", date, date).first
  end

  def create_period(date)
    return nil unless (self.user && self.user.still_active?) || self.organization

    period = Period.new(start_date: date, duration: period_duration)
    period.subscription = self

    if organization
      period.organization = organization
    else
      period.user = user
    end

    period.save

    UpdatePeriod.new(period).execute

    if organization
      UpdateOrganizationPeriod.new(period).fetch_all(true)
    end

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

  def current_preceeding_periods(period, excess_duration=12)
    if excess_duration == 12
      periods.where("start_date >= ? AND start_date < ?", self.start_date, period.start_date)
    elsif excess_duration == 3
      quarter1 = periods.where("start_date >= ? AND start_date < ?", self.start_date, self.start_date + 3.months)
      return quarter1 - [period] if quarter1.include? period

      quarter2 = periods.where("start_date >= ? AND start_date < ?", self.start_date + 3.months, self.start_date + 6.months)
      return quarter2 - [period] if quarter2.include? period

      quarter3 = periods.where("start_date >= ? AND start_date < ?", self.start_date + 6.months, self.start_date + 9.months)
      return quarter3 - [period] if quarter3.include? period

      quarter4 = periods.where("start_date >= ? AND start_date < ?", self.start_date + 9.months, self.start_date + 12.months)
      return quarter4 - [period] if quarter4.include? period

      return []
    else
      []
    end
  end

  def excess_of(period, value, max_value=nil, excess_duration=12)
    return 0 unless self.start_date.present? && self.end_date.present? && period.start_date.between?(self.start_date, self.end_date)

    max_value ||= "max_#{value.to_s}_authorized"
    current_value        = period.send(value.to_sym)
    cumulative_value     = current_preceeding_periods(period, excess_duration).map(&value.to_sym).sum
    max_authorized_value = self.send(max_value.to_sym)

    if cumulative_value > max_authorized_value
      current_value
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

  def commitment_end?(check_micro_package = true)
    if self.is_mini_package_active || ( check_micro_package && self.is_micro_package_active )
      self.end_date.strftime('%Y%m') == Time.now.strftime('%Y%m')
    else
      true
    end
  end
end
