# frozen_string_literal: true

module Account::OrdersHelper
  def quarter_names
    ['1er trimestre', '2ème trimestre', '3ème trimestre', '4ème trimestre']
  end

  def paper_set_start_date_options(order)
    order.paper_set_start_dates.map do |date|
      [paper_set_date_to_name(order.period_duration, date), date]
    end
  end

  def paper_set_end_date_options(order)
    order.paper_set_end_dates.map do |date|
      [paper_set_date_to_name(order.period_duration, date), date]
    end
  end

  def paper_set_date_to_name(period_duration, date)
    if period_duration == 1
      l(date, format: '%b %Y').capitalize
    elsif period_duration == 3
      "#{quarter_names[(date.month / 3)]} #{date.year}"
    elsif period_duration == 12
      date.year
    end
  end
end
