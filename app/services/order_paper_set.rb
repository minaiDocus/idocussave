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
    price_of_periods * 100
  end

  def periods_count
    count = 0
    date = @order.paper_set_start_date
    while date <= @order.paper_set_end_date
      count += 1
      date += @order.period_duration.month
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

  def paper_set_prices
    [
      [
        [21, 28, 35, 42, 48, 55, 62, 69, 76, 82, 89,  96, 105, 112, 118, 125, 132, 139, 146, 152, 159, 166, 173, 179],
        [21, 28, 35, 42, 49, 56, 62, 69, 76, 83, 92,  99, 106, 112, 119, 126, 133, 140, 147, 154, 160, 167, 174, 181],
        [21, 28, 35, 42, 49, 56, 63, 70, 77, 86, 93, 100, 106, 113, 120, 127, 134, 141, 148, 155, 162, 169, 175, 182],
        [22, 28, 35, 42, 49, 56, 63, 70, 79, 86, 93, 100, 107, 114, 121, 128, 135, 142, 149, 156, 163, 170, 177, 184],
        [22, 29, 36, 43, 50, 57, 64, 73, 80, 87, 94, 101, 108, 115, 122, 129, 136, 143, 150, 157, 164, 171, 178, 185],
        [22, 29, 36, 43, 50, 57, 66, 73, 80, 88, 95, 102, 109, 116, 123, 130, 137, 144, 151, 158, 165, 173, 180, 187]
      ],
      [
        [23, 31, 40, 48, 57, 65, 73, 82, 90,  99, 107, 116, 126, 135, 143, 151, 160, 168, 177, 185, 193, 202, 210, 219],
        [23, 31, 40, 48, 57, 65, 74, 82, 91,  99, 110, 118, 127, 135, 144, 152, 161, 169, 178, 186, 195, 203, 212, 220],
        [23, 32, 40, 49, 57, 66, 74, 83, 91, 102, 111, 119, 128, 136, 145, 153, 162, 170, 179, 187, 196, 205, 213, 222],
        [23, 32, 40, 49, 58, 66, 75, 83, 94, 103, 111, 120, 128, 137, 146, 154, 163, 171, 180, 189, 197, 206, 214, 223],
        [23, 32, 41, 49, 58, 66, 75, 86, 95, 103, 112, 121, 129, 138, 147, 155, 164, 173, 181, 190, 199, 207, 216, 225],
        [23, 32, 41, 49, 58, 67, 78, 86, 95, 104, 113, 121, 130, 139, 148, 156, 165, 174, 182, 191, 200, 209, 217, 226]
      ],
      [
        [25, 36, 46, 57, 68, 78, 89,  99, 110, 121, 131, 142, 155, 165, 176, 187, 197, 208, 218, 229, 240, 250, 261, 272],
        [25, 36, 47, 57, 68, 79, 89, 100, 111, 121, 134, 145, 156, 166, 177, 188, 198, 209, 220, 230, 241, 252, 262, 273],
        [25, 36, 47, 57, 68, 79, 90, 100, 111, 124, 135, 146, 156, 167, 178, 189, 199, 210, 221, 231, 242, 253, 264, 274],
        [25, 36, 47, 58, 69, 79, 90, 101, 114, 125, 136, 146, 157, 168, 179, 189, 200, 211, 222, 233, 243, 254, 265, 276],
        [25, 36, 47, 58, 69, 80, 91, 104, 114, 125, 136, 147, 158, 169, 180, 190, 201, 212, 223, 234, 245, 256, 266, 277],
        [25, 36, 47, 58, 69, 80, 93, 104, 115, 126, 137, 148, 159, 170, 181, 191, 202, 213, 224, 235, 246, 257, 268, 279]
      ]
    ]
  end
end
