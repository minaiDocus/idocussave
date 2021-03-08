# -*- encoding : UTF-8 -*-
class Subscription < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true


  has_many :periods
  has_many :documents, class_name: 'PeriodDocument'
  has_many :invoices
  has_and_belongs_to_many :options, class_name: 'SubscriptionOption', inverse_of: :subscribers

  attr_accessor :is_to_apply_now

  validates :number_of_journals, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 30 }

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

    Billing::UpdatePeriod.new(period).execute

    if organization
      Billing::UpdateOrganizationPeriod.new(period).fetch_all(true)
    end

    period
  end

  def find_or_create_period(date)
    find_period(date) || create_period(date)
  end

  def configured?
    current_packages.present?
  end

  def to_be_configured?
    self.current_packages.present? && self.futur_packages.present?
  end

  def light_package?
    !is_package?('ido_annual')
  end

  def heavy_package?
    is_package?('ido_annual') || is_package?('ido_micro') || is_package?('ido_mini') || is_package?('ido_nano')
  end

  def owner
    user || organization
  end

  def get_enabled_packages_and_options
    result = []

    result = self.futur_packages.tr('["\]','   ').tr('"', '').split(',').map { |package| package.strip().to_sym } if self.futur_packages.present?

    result
  end

  def get_active_packages_and_options
    get_active_packages + get_active_options
  end

  def get_active_packages
    period = self.current_period
    period.set_current_packages
    period.get_active_packages
  end

  def get_active_options
    period = self.current_period
    period.set_current_packages
    period.get_active_options
  end

  def current_active_package
    get_active_packages.try(:first) || :ido_classique
  end

  def is_to_be_disabled_package?(_package)
    return false if !Subscription::Package::PACKAGES_LIST.include?(_package) || !self.futur_packages

    is_package?(_package.to_s) && !self.futur_packages.include?(_package.to_s)
  end

  def is_to_be_disabled_option?(option)
    return false if !Subscription::Package::OPTIONS_LIST.include?(option) || !self.futur_packages

    is_package?(option.to_s) && !self.futur_packages.include?(option.to_s)
  end

  def is_retriever_only?
    get_active_packages.empty? && get_active_options.include?(:retriever_option)
  end

  def is_pre_assignment_really_active
    is_package?('pre_assignment_option') && (is_package?('ido_classique') || is_package?('ido_mini'))
  end

  def retriever_price_option
    organization_code = organization.try(:code) || user.organization.code
    %w(ADV).include?(organization_code) ? 'reduced_retriever'.to_sym : 'retriever'.to_sym
  end

  def set_start_date_and_end_date
    commitment_period = Subscription::Package.commitment_of(:ido_mini)  if is_package?('ido_mini')
    commitment_period = Subscription::Package.commitment_of(:ido_micro) if is_package?('ido_micro')
    commitment_period = Subscription::Package.commitment_of(:ido_nano)  if is_package?('ido_nano')

    if commitment_period.to_i > 0
      # Updating start_date and end_date when subscription term is reached
      if self.end_date.present? && self.end_date < Date.today
        self.start_date = self.period_duration == 1 ? (self.end_date + 1.day) : (self.end_date + 1.day).beginning_of_quarter
        self.end_date   = self.start_date + commitment_period.months - 1.day

        self.commitment_counter = self.commitment_counter + 1
      else
        self.start_date = self.start_date.presence || (self.period_duration == 1 ? Date.today.beginning_of_month : Date.today.beginning_of_quarter)
        self.end_date   = self.end_date.presence || (self.start_date + commitment_period.months - 1.day)
        self.commitment_counter = self.commitment_counter.presence || 1
      end
    else
      self.start_date = nil
      self.end_date   = nil
      self.commitment_counter = 1
    end

    save
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

    if cumulative_value > max_authorized_value && max_authorized_value > 0
      current_value
    elsif cumulative_value + current_value > max_authorized_value && max_authorized_value > 0
      cumulative_value + current_value - max_authorized_value
    else
      0
    end
  end

  def commitment_end?(check_micro_package = true)
    commitment_period = Subscription::Package.commitment_of(:ido_mini)  if is_package?('ido_mini')
    commitment_period = Subscription::Package.commitment_of(:ido_micro) if is_package?('ido_micro')
    commitment_period = Subscription::Package.commitment_of(:ido_nano)  if is_package?('ido_nano')

    return true if commitment_period.to_i <= 0 || (!check_micro_package && is_package?('ido_micro')) || (!check_micro_package && is_package?('ido_nano'))

    return true if (is_package?('ido_micro') || is_package?('ido_nano')) && self.commitment_counter > 1

    if is_package?('ido_mini') && self.commitment_counter > 1
      quarter1_end = (self.start_date + 3.months).strftime("%Y%m")
      quarter2_end = (self.start_date + 6.months).strftime("%Y%m")
      quarter3_end = (self.start_date + 9.months).strftime("%Y%m")
      quarter4_end = (self.start_date + 12.months).strftime("%Y%m")

      return true if [quarter1_end, quarter2_end, quarter3_end, quarter4_end].include?(Time.now.strftime("%Y%m"))
    end

    return false
  end

  def current_package?
    actual_package = ""

    actual_package = 'ido_x'                   if is_package?('ido_x')
    actual_package = 'ido_nano'                if is_package?('ido_nano')
    actual_package = 'ido_micro'               if is_package?('ido_micro')
    actual_package = 'ido_mini'                if is_package?('ido_mini')
    actual_package = 'ido_classique'           if is_package?('ido_classique')

    current_package_size = self.current_packages.tr('["\]','   ').tr('"', '').split(',').size

    actual_package = 'retriever_option' if current_package_size == 1 && is_package?('retriever_option')

    actual_package
  end

  def is_package?(package_option)
    self.user.organization.specific_mission.present? ? false : current_packages.include?(package_option)
  end
end
