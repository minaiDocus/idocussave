# -*- encoding : UTF-8 -*-
module Account::SubscriptionsHelper
  def is_product_option_checked?(index, option, options)
    if option.product_group.is_option_dependent
      if options.any?
        option.in? options
      else
        index == 0 ? true : false
      end
    else
      option.in? options
    end
  end

  def is_product_option_disabled?(option, group, options)
    if @user.is_admin
      false
    else
      if Settings.is_subscription_lower_options_disabled
        selected_option = options.select { |option| option.product_group == group }.first
        selected_option ? option.position < selected_option.position : false
      else
        false
      end
    end
  end

  def retrievers_option_warning_class(customer, option)
    if customer && customer.fiduceo_id.present? && option.action_name == 'unauthorize_fiduceo' && customer.fiduceo_retrievers.size > 0
      ' warn_for_deletion_of_retrievers'
    else
      ''
    end
  end
end
