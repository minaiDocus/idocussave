# -*- encoding : UTF-8 -*-
class PeriodService
  attr_accessor :period_duration, :authd_prev_period, :auth_prev_period_until_day, :auth_prev_period_until_month, :current_time

  def initialize(options)
    if options[:user]
      @period_duration              = options[:user].periods.desc(:start_at).first.try(:duration)
      @authd_prev_period            = options[:user].authd_prev_period
      @auth_prev_period_until_day   = options[:user].auth_prev_period_until_day.try(:day)
      @auth_prev_period_until_month = options[:user].auth_prev_period_until_month.try(:month)
    end
    @period_duration              ||= options[:period_duration]                          || 1
    @authd_prev_period            ||= options[:authd_prev_period]                        || 1
    @auth_prev_period_until_day   ||= options[:auth_prev_period_until_day].try(:day)     || 11.day
    @auth_prev_period_until_month ||= options[:auth_prev_period_until_month].try(:month) || 0.month
    @current_time                 = options[:current_time] || Time.now
  end

  def start_at
    month_count = @period_duration * @authd_prev_period
    (@current_time - month_count.months).beginning_of_month
  end

  def end_at
    if @period_duration == 1
      @current_time.end_of_month
    elsif @period_duration == 3
      @current_time.end_of_quarter
    end
  end

  def include?(param)
    if param.class.in? [Time, ActiveSupport::TimeWithZone]
      start_at <= param && end_at >= param
    elsif param.class == String
      names.include? param
    else
      nil
    end
  end

  def names
    time = @current_time.beginning_of_month   if @period_duration == 1
    time = @current_time.beginning_of_quarter if @period_duration == 3
    (@authd_prev_period + 1).times.map do |i|
      Scan::Period.period_name(@period_duration, @authd_prev_period - i, time)
    end
  end

  def prev_expires_at
    if @auth_prev_period_until_month == 0 && @auth_prev_period_until_day == 0
      nil
    else
      beginning_of_month = (@current_time + @auth_prev_period_until_month).beginning_of_month
      day = @auth_prev_period_until_day - 1.day
      (beginning_of_month + day).end_of_day
    end
  end

  class << self
    def total_price_in_cents_wo_vat(time, periods)
      monthly_periods = periods.select{ |period| period.duration == 1 }
      quarterly_periods = periods.select do |period|
        period.duration == 3 && (time.month == time.end_of_quarter.month || period.is_charged_several_times)
      end

      total = monthly_periods.sum(&:price_in_cents_wo_vat)
      quarterly_periods.each do |period|
        if period.is_charged_several_times
          total += period.recurrent_products_price_in_cents_wo_vat
          if time.month == time.beginning_of_quarter.month
            total += period.ponctual_products_price_in_cents_wo_vat
          end
          if time.month == time.end_of_quarter.month
            total += period.excesses_price_in_cents_wo_vat
          end
        else
          total += period.price_in_cents_wo_vat
        end
      end
      total
    end

    def vat_ratio(time)
      if time < Time.local(2014,1,1)
        1.196
      else
        1.2
      end
    end
  end
end
