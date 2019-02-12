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
        [25, 33, 41, 48, 56, 64, 72, 80, 88, 96,  103, 111, 122, 130, 138, 145, 153, 161, 169, 177, 185, 193, 201, 208],
        [25, 33, 41, 49, 57, 65, 72, 80, 88, 96,  107, 115, 123, 131, 139, 147, 154, 162, 170, 178, 186, 194, 202, 210],
        [25, 33, 41, 49, 57, 65, 73, 81, 89, 100, 108, 116, 124, 132, 140, 148, 156, 164, 172, 180, 188, 196, 204, 212],
        [25, 33, 41, 49, 57, 65, 73, 82, 92, 100, 108, 116, 125, 133, 141, 149, 157, 165, 173, 181, 189, 197, 205, 213],
        [25, 33, 41, 50, 58, 66, 74, 85, 93, 101, 109, 117, 125, 134, 142, 150, 158, 166, 174, 183, 191, 199, 207, 215],
        [25, 33, 42, 50, 58, 66, 77, 85, 93, 102, 110, 118, 126, 135, 143, 151, 159, 167, 176, 184, 192, 200, 209, 217]
      ],
      [
        [29, 40, 50, 61, 71, 82, 93, 103, 114, 124, 135, 146, 159, 170, 180, 191, 201, 212, 223, 233, 244, 254, 265, 276],
        [29, 40, 50, 61, 72, 82, 93, 104, 114, 125, 139, 149, 160, 171, 181, 192, 203, 213, 224, 235, 245, 256, 267, 277],
        [29, 40, 51, 61, 72, 83, 94, 104, 115, 129, 139, 150, 161, 172, 182, 193, 204, 215, 225, 236, 247, 258, 268, 279],
        [29, 40, 51, 62, 72, 83, 94, 105, 118, 129, 140, 151, 162, 173, 184, 194, 205, 216, 227, 238, 249, 259, 270, 281],
        [29, 40, 51, 62, 73, 84, 95, 108, 119, 130, 141, 152, 163, 174, 185, 196, 207, 217, 228, 239, 250, 261, 272, 283],
        [29, 40, 51, 62, 73, 84, 98, 109, 120, 131, 142, 153, 164, 175, 186, 197, 208, 219, 230, 241, 252, 263, 274, 285]
      ],
      [
        [31, 43, 56, 69, 82, 95, 108, 121, 134, 147, 160, 173, 188, 201, 214, 227, 240, 253, 266, 278, 291, 304, 317, 330],
        [31, 44, 57, 70, 83, 96, 109, 122, 134, 147, 163, 176, 189, 202, 215, 228, 241, 254, 267, 280, 293, 306, 319, 332],
        [31, 44, 57, 70, 83, 96, 109, 122, 135, 151, 164, 177, 190, 203, 216, 229, 242, 255, 268, 281, 294, 308, 321, 334],
        [31, 44, 57, 70, 83, 96, 110, 123, 138, 152, 165, 178, 191, 204, 217, 230, 243, 257, 270, 283, 296, 309, 322, 335],
        [31, 44, 57, 70, 84, 97, 110, 126, 139, 152, 166, 179, 192, 205, 218, 232, 245, 258, 271, 284, 298, 311, 324, 337],
        [31, 44, 58, 71, 84, 97, 113, 127, 140, 153, 166, 180, 193, 206, 219, 233, 246, 259, 273, 286, 299, 312, 326, 339]
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
