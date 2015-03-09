# -*- encoding : UTF-8 -*-
module Account::SubscriptionsHelper
  def is_product_option_checked?(index, option, options)
    if option.product_group.is_option_dependent
      if options.include? option
        true
      elsif options.map(&:product_group).include?(option.product_group)
        false
      else
        index == 0
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
        if group.is_option_dependent
          selected_option = options.select { |option| option.product_group == group }.first
          selected_option ? option.position < selected_option.position : false
        else
          option.in? options
        end
      else
        false
      end
    end
  end

  def retrievers_option_warning_class(customer, option)
    if customer && customer.fiduceo_id.present?
      if option.product_group.is_option_dependent
        if option.action_names.include? 'authorize_fiduceo'
          ' authorize_retrievers'
        elsif option.product_group.product_options.map(&:action_names).flatten.include?('authorize_fiduceo')
          ' warn_for_deletion_of_retrievers' if customer.fiduceo_retrievers.size > 0
        end
      elsif option.action_names.include? 'authorize_fiduceo'
        ' warn_for_deletion_of_retrievers' if customer.fiduceo_retrievers.size > 0
      end
    end
  end
end
