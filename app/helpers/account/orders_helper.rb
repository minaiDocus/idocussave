# -*- encoding : UTF-8 -*-
module Account::OrdersHelper
  def quarter_names
    ['1er trimestre', '2ème trimestre', '3ème trimestre', '4ème trimestre']
  end

  def paper_set_start_date_options(period_duration)
    date = Date.today.beginning_of_month
    if period_duration == 12
      maximum_date = date - 36.months
    else
      maximum_date = date - 12.months
    end
    options = []
    while date >= maximum_date
      options << [paper_set_date_to_name(period_duration, date), date]
      date -= period_duration.months
    end
    options
  end

  def paper_set_end_date_options(period_duration)
    date = Date.today.beginning_of_month
    maximum_date = date.end_of_year
    options = []
    while date <= maximum_date
      options << [paper_set_date_to_name(period_duration, date), date]
      date += period_duration.months
    end
    options
  end

  def paper_set_date_to_name(period_duration, date)
    if period_duration == 1
      l(date, format: '%b %Y').capitalize
    elsif period_duration == 3
      "#{quarter_names[(date.month/3)]} #{date.year}"
    elsif period_duration == 12
      date.year
    end
  end
end
