# -*- encoding : UTF-8 -*-
class Billing::Period
  attr_accessor :period_duration, :authd_prev_period, :auth_prev_period_until_day, :auth_prev_period_until_month, :current_time


  def initialize(options)
    if options[:user]
      @period_duration   = options[:user].periods.order(start_date: :desc).first.try(:duration)
      @authd_prev_period = options[:user].authd_prev_period
      @auth_prev_period_until_day   = options[:user].auth_prev_period_until_day.try(:day)
      @auth_prev_period_until_month = options[:user].auth_prev_period_until_month.try(:month)
    end

    @period_duration   ||= options[:period_duration] || 1
    @authd_prev_period ||= options[:authd_prev_period] || 1
    @auth_prev_period_until_day   ||= options[:auth_prev_period_until_day].try(:day) || 11.day
    @auth_prev_period_until_month ||= options[:auth_prev_period_until_month].try(:month) || 0.month

    @current_time = options[:current_time] || Time.now
  end


  def start_at
    month_count = @period_duration * @authd_prev_period

    (@current_time - month_count.months).beginning_of_month
  end


  def end_at
    case @period_duration
    when 1
      @current_time.end_of_month
    when 3
      @current_time.end_of_quarter
    when 12
      @current_time.end_of_year
    end
  end


  def include?(param)
    if param.class.in? [Time, ActiveSupport::TimeWithZone]
      start_at <= param && end_at >= param
    elsif param.class == String
      names.include? param
    end
  end


  def names
    case @period_duration
    when 1
      time = @current_time.beginning_of_month
    when 3
      time = @current_time.beginning_of_quarter
    when 12
      time = @current_time.beginning_of_year
    end

    Array.new((@authd_prev_period + 1)) do |i|
      Period.period_name(@period_duration, @authd_prev_period - i, time)
    end
  end


  def prev_expires_at
    if @auth_prev_period_until_month == 0 && @auth_prev_period_until_day == 0
      nil
    else
      case @period_duration
      when 1
        beginning = @current_time
      when 3
        beginning = @current_time.beginning_of_quarter
      when 12
        beginning = @current_time.beginning_of_year
      end

      beginning_of_month = (beginning + @auth_prev_period_until_month).beginning_of_month

      day = @auth_prev_period_until_day - 1.day

      (beginning_of_month + day).end_of_day
    end
  end
end
