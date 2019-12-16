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

    return false if @order.period_duration == 3

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
    discount_price * 100
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


  def discount_price
    unit_price = 0
    selected_casing_count = @order.paper_set_casing_count
    max_casing_count = periods_count

    case casing_size_index
      when 0
        unit_price = 6
      when 1
        unit_price = 9
      when 2
        unit_price = 12
      else
        unit_price = 0
    end

    if selected_casing_count > 0 && max_casing_count > 0
      discount_price = unit_price * (max_casing_count - selected_casing_count)
      price_of_periods - discount_price
    else
      price_of_periods
    end
  end

  def paper_set_prices
    [
      [
        [26, 34, 43, 51, 59, 67, 76, 84, 37, 100, 109, 117, 128, 136, 144, 153, 161, 169, 177, 186, 194, 202, 211, 219],
        [26, 34, 43, 51, 59, 68, 76, 84, 93, 101, 112, 121, 129, 137, 146, 154, 162, 171, 179, 187, 196, 204, 212, 221],
        [26, 35, 43, 51, 60, 68, 77, 85, 93, 105, 113, 121, 130, 138, 147, 155, 163, 172, 180, 189, 197, 206, 214, 222],
        [26, 35, 43, 52, 60, 69, 77, 86, 97, 105, 114, 122, 131, 139, 148, 156, 165, 173, 182, 190, 199, 207, 216, 224],
        [26, 35, 43, 52, 61, 69, 78, 89, 97, 106, 115, 123, 132, 140, 149, 157, 166, 175, 183, 192, 200, 209, 217, 226],
        [26, 35, 44, 52, 61, 70, 81, 90, 98, 107, 115, 124, 133, 141, 150, 159, 167, 176, 184, 193, 202, 210, 219, 228]
      ],
      [
        [30, 42, 53, 64, 75, 86, 97, 108, 119, 131, 142, 153, 167, 178, 189, 200, 211, 223, 234, 245, 256, 267, 278, 289],
        [30, 42, 53, 64, 75, 87, 98, 109, 120, 131, 146, 157, 168, 179, 190, 202, 213, 224, 235, 246, 258, 269, 280, 291],
        [31, 42, 53, 64, 76, 87, 98, 110, 121, 135, 146, 158, 169, 180, 192, 203, 214, 225, 237, 248, 259, 271, 282, 293],
        [31, 42, 53, 65, 76, 87, 99, 110, 124, 136, 147, 159, 170, 181, 193, 204, 216, 227, 238, 250, 261, 272, 284, 295],
        [31, 42, 54, 65, 77, 88, 99, 114, 125, 137, 148, 160, 171, 183, 194, 205, 217, 228, 240, 251, 263, 274, 286, 297],
        [31, 42, 54, 65, 77, 88, 103, 114, 126, 137, 149, 161, 172, 184, 195, 207, 218, 230, 241, 253, 264, 276, 287, 299]
      ],
      [
        [32, 46, 59, 73, 86, 100, 113, 127, 141, 154, 168, 181, 198, 211, 225, 238, 252, 265, 279, 292, 306, 319, 333, 347],
        [32, 46, 59, 73, 87, 100, 114, 128, 141, 155, 171, 185, 199, 212, 226, 239, 253, 267, 280, 294, 308, 321, 335, 348],
        [32, 46, 60, 73, 87, 101, 114, 128, 142, 158, 172, 186, 200, 213, 227, 241, 254, 268, 282, 295, 309, 323, 337, 350],
        [32, 46, 60, 74, 87, 101, 115, 129, 145, 159, 173, 187, 201, 214, 228, 242, 256, 269, 283, 297, 311, 325, 338, 352],
        [32, 46, 60, 74, 88, 102, 116, 132, 146, 160, 174, 188, 202, 215, 229, 243, 257, 271, 285, 299, 312, 326, 340, 354],
        [33, 46, 60, 74, 88, 102, 119, 133, 147, 161, 175, 189, 203, 216, 230, 244, 258, 272, 286, 300, 314, 328, 342, 356]
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
