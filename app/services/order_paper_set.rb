# -*- encoding : UTF-8 -*-
class OrderPaperSet
  def initialize(user, order, is_an_update=false)
    @user         = user
    @order        = order
    @period       = user.subscription.current_period
    @is_an_update = is_an_update
  end

  def execute
    @order.user ||= @user
    @order.organization ||= @user.organization
    @order.period_duration = @period.duration
    @order.price_in_cents_wo_vat = price_in_cents_wo_vat
    if @order.save
      unless @is_an_update
        @period.orders << @order
        ConfirmOrder.execute(@order.id.to_s)
      end
      UpdatePeriod.new(@period).execute
      true
    else
      false
    end
  end

private

  def price_in_cents_wo_vat
    (price_of_periods + price_of_previous_periods) * 100
  end

  def periods_count
    count = 0
    date = Date.today.beginning_of_month
    while date <= @order.paper_set_end_date
      count += 1
      date += @order.period_duration.month
    end
    count
  end

  def previous_periods_count
    count = 0
    date = Date.today.beginning_of_month
    while date > @order.paper_set_start_date
      count += 1
      date -= @order.period_duration.month
    end
    count
  end

  def casing_size_index
    case @order.paper_set_casing_size
    when 500
      0
    when 1000
      1
    when 3000
      2
    end
  end

  def folder_count_index
    @order.paper_set_folder_count - 5
  end

  def price_of_periods
    paper_set_prices[casing_size_index][folder_count_index][periods_count - 1]
  end

  def price_of_previous_periods
    if previous_periods_count > 0
      paper_set_prices[casing_size_index][folder_count_index][previous_periods_count - 1]
    else
      0
    end
  end

  def paper_set_prices
    [
      [
        [21, 28, 35, 42, 48, 55, 62, 69, 76, 82, 89,  96],
        [21, 28, 35, 42, 49, 56, 62, 69, 76, 83, 92,  99],
        [21, 28, 35, 42, 49, 56, 63, 70, 77, 86, 93, 100],
        [22, 28, 35, 42, 49, 56, 63, 70, 79, 86, 93, 100],
        [22, 29, 36, 43, 50, 57, 64, 73, 80, 87, 94, 101],
        [22, 29, 36, 43, 50, 57, 66, 73, 80, 88, 95, 102]
      ],
      [
        [23, 31, 40, 48, 57, 65, 73, 82, 90,  99, 107, 116],
        [23, 31, 40, 48, 57, 65, 74, 82, 91,  99, 110, 118],
        [23, 32, 40, 49, 57, 66, 74, 83, 91, 102, 111, 119],
        [23, 32, 40, 49, 58, 66, 75, 83, 94, 103, 111, 120],
        [23, 32, 41, 49, 58, 66, 75, 86, 95, 103, 112, 121],
        [23, 32, 41, 49, 58, 67, 78, 86, 95, 104, 113, 121]
      ],
      [
        [25, 36, 46, 57, 68, 78, 89,  99, 110, 121, 131, 142],
        [25, 36, 47, 57, 68, 79, 89, 100, 111, 121, 134, 145],
        [25, 36, 47, 57, 68, 79, 90, 100, 111, 124, 135, 146],
        [25, 36, 47, 58, 69, 79, 90, 101, 114, 125, 136, 146],
        [25, 36, 47, 58, 69, 80, 91, 104, 114, 125, 136, 147],
        [25, 36, 47, 58, 69, 80, 93, 104, 115, 126, 137, 148]
      ]
    ]
  end
end
