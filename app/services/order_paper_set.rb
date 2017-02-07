# -*- encoding : UTF-8 -*-
class OrderPaperSet
  def initialize(user, order, is_an_update = false)
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
    @order.address.is_for_paper_set_shipping = true if @order.address
    if @order.save
      unless @is_an_update
        @period.orders << @order
        ConfirmOrder.delay_for(24.hours).execute(@order.id)
      end

      auto_ajust_number_of_journals_authorized

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
        [22, 29, 36, 44, 50, 57, 65, 72, 79, 86, 93, 100, 110, 117, 123, 131, 138, 145, 153, 159, 166, 174, 181, 187],
        [23, 30, 37, 45, 51, 58, 66, 73, 80, 87, 94, 101, 111, 118, 124, 132, 139, 146, 154, 160, 167, 175, 182, 188],
        [24, 31, 38, 46, 52, 59, 67, 74, 81, 88, 95, 102, 112, 119, 125, 133, 140, 147, 155, 161, 168, 176, 183, 189],
        [25, 32, 39, 47, 53, 60, 68, 75, 82, 89, 96, 103, 113, 120, 126, 134, 141, 148, 156, 162, 169, 177, 184, 190],
        [26, 33, 40, 48, 54, 61, 69, 76, 83, 90, 97, 104, 114, 121, 127, 135, 142, 149, 157, 163, 170, 178, 185, 191],
        [27, 34, 41, 49, 55, 62, 70, 77, 84, 91, 98, 105, 115, 122, 128, 136, 143, 150, 158, 164, 171, 179, 186, 192]
      ],
      [
        [24, 32, 42, 50, 59, 68, 76, 86, 94, 103, 112, 121, 132, 141, 150, 158, 168, 176, 185, 194, 202, 212, 220, 229],
        [25, 33, 43, 51, 60, 69, 77, 87, 95, 104, 113, 122, 133, 142, 151, 159, 169, 177, 186, 195, 203, 213, 221, 230],
        [26, 34, 44, 52, 61, 70, 78, 88, 96, 105, 114, 123, 134, 143, 152, 160, 170, 178, 187, 196, 204, 214, 222, 231],
        [27, 35, 45, 53, 62, 71, 79, 89, 97, 106, 115, 124, 135, 144, 153, 161, 171, 179, 188, 197, 205, 215, 223, 232],
        [28, 36, 46, 54, 63, 72, 80, 90, 98, 107, 116, 125, 136, 145, 154, 162, 172, 180, 189, 198, 206, 216, 224, 233],
        [29, 37, 47, 55, 64, 73, 81, 91, 99, 108, 117, 126, 137, 146, 155, 163, 173, 181, 190, 199, 207, 217, 225, 234]
      ],
      [
        [26, 37, 48, 59, 71, 81, 93, 103, 115, 127, 137, 149, 162, 173, 184, 196, 206, 218, 228, 240, 252, 262, 274, 285],
        [27, 38, 49, 60, 72, 82, 94, 104, 116, 128, 138, 150, 163, 174, 185, 197, 207, 219, 229, 241, 253, 263, 275, 286],
        [28, 39, 50, 61, 73, 83, 95, 105, 117, 129, 139, 151, 164, 175, 186, 198, 208, 220, 230, 242, 254, 264, 276, 287],
        [29, 40, 51, 62, 74, 84, 96, 106, 118, 130, 140, 152, 165, 176, 187, 199, 209, 221, 231, 243, 255, 265, 277, 288],
        [30, 41, 52, 63, 75, 85, 97, 107, 119, 131, 141, 153, 166, 177, 188, 200, 210, 222, 232, 244, 256, 266, 278, 289],
        [31, 42, 53, 64, 76, 86, 98, 108, 120, 132, 142, 154, 167, 178, 189, 201, 211, 223, 233, 245, 257, 267, 279, 290]
      ]
    ]
  end


  def auto_ajust_number_of_journals_authorized
    if @order.paper_set_folder_count != @user.subscription.number_of_journals && @order.paper_set_folder_count >= @user.account_book_types.count
      @user.subscription.number_of_journals = @order.paper_set_folder_count
      EvaluateSubscription.new(@user.subscription).execute if @user.subscription.save
    end
  end
end
