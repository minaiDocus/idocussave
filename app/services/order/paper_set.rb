# -*- encoding : UTF-8 -*-
class Order::PaperSet
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

        if @order.normal_paper_set_order?
          Order::Confirm.delay_for(24.hours).execute(@order.id)
        else
          @order.confirm if @order.pending?
        end
      end

      auto_ajust_number_of_journals_authorized

      Billing::UpdatePeriod.new(@period).execute

      true
    else
      false
    end
  end

  def self.paper_set_prices
    [
      [
        [27, 36, 44, 53, 62, 70, 79, 88, 96, 105, 113, 122, 133, 142, 151, 159, 168, 177, 185, 194, 202, 211, 220, 228],
        [27, 36, 45, 53, 62, 71, 79, 88, 97, 106, 117, 126, 134, 143, 152, 161, 169, 178, 187, 195, 204, 213, 222, 230],
        [27, 36, 45, 54, 62, 71, 80, 89, 98, 109, 118, 127, 135, 144, 153, 162, 171, 179, 188, 197, 206, 215, 223, 232],
        [27, 36, 45, 54, 63, 72, 81, 89, 101, 110, 119, 128, 136, 145, 154, 163, 172, 181, 190, 198, 207, 216, 225, 234],
        [27, 36, 45, 54, 63, 72, 81, 93, 102, 111, 120, 129, 137, 146, 155, 164, 173, 182, 191, 200, 209, 218, 227, 236],
        [28, 37, 46, 55, 64, 73, 84, 93, 102, 111, 120, 129, 138, 147, 157, 166, 175, 184, 193, 202, 211, 220, 229, 238]
      ],
      [
        [32, 43, 55, 67, 78, 90, 102, 113, 125, 137, 148, 160, 175, 186, 198, 210, 221, 233, 245, 256, 268, 280, 291, 303],
        [32, 44, 55, 67, 79, 91, 102, 114, 126, 138, 152, 164, 176, 188, 199, 211, 223, 235, 246, 258, 270, 282, 293, 305],
        [32, 44, 56, 67, 79, 91, 103, 115, 127, 141, 153, 165, 177, 189, 201, 212, 224, 236, 248, 260, 272, 283, 295, 307],
        [32, 44, 56, 68, 80, 92, 104, 115, 130, 142, 154, 166, 178, 190, 202, 214, 226, 238, 250, 261, 273, 285, 297, 309],
        [32, 44, 56, 68, 80, 92, 104, 119, 131, 143, 155, 167, 179, 191, 203, 215, 227, 239, 251, 263, 275, 287, 299, 311],
        [32, 44, 56, 68, 81, 93, 108, 120, 132, 144, 156, 168, 180, 192, 204, 216, 229, 241, 253, 265, 277, 289, 301, 313]
      ],
      [
        [33, 47, 61, 75, 89, 103, 117, 131, 145, 159, 173, 187, 204, 218, 232, 246, 260, 274, 288, 302, 316, 330, 344, 358],
        [33, 47, 61, 75, 90, 104, 118, 132, 146, 160, 177, 191, 205, 219, 233, 247, 261, 275, 289, 303, 317, 332, 346, 360],
        [33, 47, 62, 76, 90, 104, 118, 132, 146, 164, 178, 192, 206, 220, 234, 248, 263, 277, 291, 305, 319, 333, 347, 362],
        [33, 48, 62, 76, 90, 105, 119, 133, 150, 164, 179, 193, 207, 221, 235, 250, 264, 278, 292, 307, 321, 335, 349, 364],
        [33, 48, 62, 76, 91, 105, 119, 137, 151, 165, 179, 194, 208, 222, 237, 251, 265, 280, 294, 308, 322, 337, 351, 365],
        [34, 48, 62, 77, 91, 105, 123, 137, 152, 166, 180, 195, 209, 223, 238, 252, 267, 281, 295, 310, 324, 339, 353, 367]
      ]
    ]
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
    return 0 # TODO...

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
    Order::PaperSet.paper_set_prices[casing_size_index][folder_count_index][periods_count - 1]
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

    if @order.normal_paper_set_order?
      if selected_casing_count && selected_casing_count > 0 && max_casing_count > 0
        discount_price = unit_price * (max_casing_count - selected_casing_count)
        price_of_periods - discount_price
      else
        price_of_periods
      end
    else # When organization applied manuel paper set order
      (@order.paper_set_folder_count * periods_count) * 0 #No price for manual kit generation
    end
  end

  def auto_ajust_number_of_journals_authorized
    if @order.paper_set_folder_count != @user.subscription.number_of_journals && @order.paper_set_folder_count >= @user.account_book_types.count
      @user.subscription.number_of_journals = @order.paper_set_folder_count
      Subscription::Evaluate.new(@user.subscription).execute if @user.subscription.save
    end
  end
end
