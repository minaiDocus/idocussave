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
        [24, 31, 39, 48, 54, 62, 70, 78, 85, 93, 100, 108, 119, 126, 133, 141, 149, 157, 165, 172, 179, 188, 195, 202],
        [25, 32, 40, 49, 55, 63, 71, 79, 86, 94, 102, 109, 120, 127, 134, 143, 150, 158, 166, 173, 180, 189, 197, 203],
        [26, 33, 41, 50, 56, 64, 72, 80, 87, 95, 103, 110, 121, 129, 135, 144, 151, 159, 167, 174, 181, 190, 198, 204],
        [27, 35, 42, 51, 57, 65, 73, 81, 89, 96, 104, 111, 122, 130, 136, 145, 152, 160, 168, 175, 183, 191, 199, 205],
        [28, 36, 43, 52, 58, 66, 75, 82, 90, 97, 105, 112, 123, 131, 137, 146, 153, 161, 170, 176, 184, 192, 200, 206],
        [29, 37, 44, 53, 59, 67, 76, 83, 91, 98, 106, 113, 124, 132, 138, 147, 154, 162, 171, 177, 185, 193, 201, 207]
      ],
      [
        [26, 35, 45, 54, 64, 73, 82, 93, 102, 111, 121, 131, 143, 152, 162, 171, 181, 190, 200, 210, 218, 229, 238, 247],
        [27, 36, 46, 55, 65, 75, 83, 94, 103, 112, 122, 132, 144, 153, 163, 172, 183, 191, 201, 211, 219, 230, 239, 248],
        [28, 37, 48, 56, 66, 76, 84, 95, 104, 113, 123, 133, 145, 154, 164, 173, 184, 192, 202, 212, 220, 231, 240, 249],
        [29, 38, 49, 57, 67, 77, 85, 96, 105, 114, 124, 134, 146, 156, 165, 174, 185, 193, 203, 213, 221, 232, 241, 251],
        [30, 39, 50, 58, 68, 78, 86, 97, 106, 116, 125, 135, 147, 157, 166, 175, 186, 194, 204, 214, 222, 233, 242, 252],
        [31, 40, 51, 59, 69, 79, 87, 98, 107, 117, 126, 136, 148, 158, 167, 176, 187, 195, 205, 215, 224, 234, 243, 253]
      ],
      [
        [28, 40, 52, 64, 77, 87, 100, 111, 124, 137, 148, 161, 175, 187, 199, 212, 222, 235, 246, 259, 272, 283, 296, 308],
        [29, 41, 53, 65, 78, 89, 102, 112, 125, 138, 149, 162, 176, 188, 200, 213, 224, 237, 247, 260, 273, 284, 297, 309],
        [30, 42, 54, 66, 79, 90, 103, 113, 126, 139, 150, 163, 177, 189, 201, 214, 225, 238, 248, 261, 274, 285, 298, 310],
        [31, 43, 55, 67, 80, 91, 104, 114, 127, 140, 151, 164, 178, 190, 202, 215, 226, 239, 249, 262, 275, 286, 299, 311],
        [32, 44, 56, 68, 81, 92, 105, 116, 129, 141, 152, 165, 179, 191, 203, 216, 227, 240, 251, 264, 276, 287, 300, 312],
        [33, 45, 57, 69, 82, 93, 106, 117, 130, 143, 153, 166, 180, 192, 204, 217, 228, 241, 252, 265, 278, 288, 301, 313]
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
