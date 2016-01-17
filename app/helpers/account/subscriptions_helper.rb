# -*- encoding : UTF-8 -*-
module Account::SubscriptionsHelper
  def option_warning_classes(customer, option)
    retrievers_option_warning_class(customer, option).to_s +
    preassignment_option_warning_class(customer, option).to_s
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

  def preassignment_option_warning_class(customer, option)
    if option.product_group.is_option_dependent
      if option.action_names.include? 'authorize_preassignment'
        ' authorize_preassignment' if customer.account_book_types.pre_assignment_processable.count > 0
      elsif option.product_group.product_options.map(&:action_names).flatten.include?('authorize_preassignment')
        ' warn_for_deletion_of_preassignment' if customer.account_book_types.pre_assignment_processable.count > 0
      end
    elsif option.action_names.include? 'authorize_preassignment'
      ' warn_for_deletion_of_preassignment' if customer.account_book_types.pre_assignment_processable.count > 0
    end
  end
end
