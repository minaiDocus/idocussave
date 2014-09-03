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
      selected_option = @subscription.product_option_orders.select{ |so| group_options.select{ |go| is_same_option?(go, so) }.present? }.first
      selected_option ? option.position < selected_option.position : false
    end
  end

  def is_same_option?(option1, option2)
    result = true
    result = false unless option1.name        == option2.name
    result = false unless option1.title       == option2.title
    result = false unless option1.group_title == option2.group_title
    result = false unless option1.description == option2.description
    result = false unless option1.duration    == option2.duration
    result = false unless option1.quantity    == option2.quantity
    result = false unless option1.action_name == option2.action_name
    result = false unless option1.notify      == option2.notify
    result
  end
end
