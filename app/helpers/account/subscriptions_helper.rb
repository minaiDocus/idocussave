# -*- encoding : UTF-8 -*-
module Account::SubscriptionsHelper
  def is_product_option_checked?(index, option, options)
    if option.product_group.is_option_dependent
      if options.any?
        options.map{ |option| option[0] }.include?(option.first_attribute)
      else
        index == 0 ? true : false
      end
    else
      option.to_a.in?(options)
    end
  end

  def is_product_option_disabled?(option, group)
    if @user.is_admin
      false
    else
      group_options = group.product_options
      selected_option = @subscription.product_option_orders.select{ |so| group_options.select{ |go| so == go }.present? }.first
      selected_option ? option.position < selected_option.position : false
    end
  end
end
