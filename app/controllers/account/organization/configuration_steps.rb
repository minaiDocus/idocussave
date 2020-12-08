# frozen_string_literal: true

module Account::Organization::ConfigurationSteps
  extend ActiveSupport::Concern

  protected

  def redirect_to_current_step
    if @customer && !@customer.configured? && !current_step?
      redirect_to step_path(@customer.current_configuration_step)
    end
  end

  def next_configuration_step
    was_last_step = last_step?
    @customer.current_configuration_step = case @customer.current_configuration_step
                                           when 'account'
                                             'subscription'
                                           when 'subscription'
                                             if @customer.subscription.is_package?('pre_assignment_option')
                                               'compta_options'
                                             elsif @organization.uses_softwares?
                                               'softwares_selection'
                                             elsif @customer.options.is_upload_authorized
                                               'period_options'
                                             else
                                               'journals'
                                             end
                                           when 'compta_options'
                                             if @organization.uses_softwares?
                                               'softwares_selection'
                                             else
                                               'period_options'
                                             end
                                           when 'softwares_selection'
                                             if @customer.options.is_upload_authorized
                                               'period_options'
                                             else
                                               'journals'
                                             end
                                           when 'period_options'
                                             if @customer.subscription.is_package?('pre_assignment_option')
                                               if @organization.ibiza.try(:configured?) && @customer.uses?(:ibiza)
                                                 'ibiza'
                                               elsif @customer.uses?(:csv_descriptor)
                                                 'use_csv_descriptor'
                                               elsif !@customer.uses_api_softwares?
                                                 'accounting_plans'
                                               else
                                                 'journals'
                                               end
                                             else
                                               'journals'
                                             end
                                           when 'use_csv_descriptor'
                                             if @customer.try(:csv_descriptor).try(:use_own_csv_descriptor_format)
                                               'csv_descriptor'
                                             elsif !@customer.uses_api_softwares?
                                               'accounting_plans'
                                             else
                                               'journals'
                                             end
                                           when 'csv_descriptor'
                                             if !@customer.uses_api_softwares?
                                               'accounting_plans'
                                             else
                                               'journals'
                                             end
                                           when 'accounting_plans'
                                             'vat_accounts'
                                           when 'vat_accounts'
                                             'journals'
                                           when 'ibiza'
                                             'journals'
                                           when 'journals'
                                             if @customer.subscription.is_package?('mail_option')
                                               if @customer.account_book_types.count > 0
                                                 'order_paper_set'
                                               else
                                                 flash[:error] = 'Vous devez configurer au moins un journal comptable.'
                                                 'journals'
                                               end
                                             elsif @customer.is_dematbox_authorized
                                               'order_dematbox'
                                             elsif @organization.knowings.try(:configured?)
                                               'ged'
                                             end
                                           when 'order_paper_set'
                                             if @customer.is_dematbox_authorized
                                               'order_dematbox'
                                             elsif @organization.knowings.try(:configured?)
                                               'ged'
                                             end
                                           when 'order_dematbox'
                                             if @organization.knowings.try(:configured?)
                                               'ged'
                                             end
                                           when 'ged'
                                             nil
    end

    @customer.save
    if @customer.current_configuration_step
      redirect_to step_path(@customer.current_configuration_step)
    else
      flash[:success] = 'Dossier configuré avec succès.' if was_last_step
      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end

  def previous_configuration_step
    @customer.current_configuration_step = case @customer.current_configuration_step
                                           when 'ged'
                                             if @customer.is_dematbox_authorized
                                               'order_dematbox'
                                             elsif @customer.subscription.is_package?('mail_option')
                                               'order_paper_set'
                                             else
                                               'journals'
                                            end
                                           when 'order_dematbox'
                                             if @customer.subscription.is_package?('mail_option')
                                               'order_paper_set'
                                             else
                                               'journals'
                                             end
                                           when 'order_paper_set'
                                             'journals'
                                           when 'journals'
                                             if @customer.subscription.is_package?('pre_assignment_option')
                                               if @organization.ibiza.try(:configured?) && @customer.uses?(:ibiza)
                                                 'ibiza'
                                               elsif !@customer.uses_api_softwares?
                                                 'vat_accounts'
                                               elsif @customer.options.is_upload_authorized
                                                 'period_options'
                                               elsif @organization.uses_softwares?
                                                 'softwares_selection'
                                               elsif @customer.subscription.is_package?('pre_assignment_option')
                                                 'compta_options'
                                               else
                                                 'subscription'
                                               end
                                             elsif @customer.options.is_upload_authorized
                                               'period_options'
                                             elsif @organization.uses_softwares?
                                               'softwares_selection'
                                             elsif @customer.subscription.is_package?('pre_assignment_option')
                                               'compta_options'
                                             else
                                               'subscription'
                                             end
                                           when 'ibiza'
                                             'period_options'
                                           when 'vat_accounts'
                                             'accounting_plans'
                                           when 'accounting_plans'
                                             if @customer.try(:csv_descriptor).try(:use_own_csv_descriptor_format)
                                               'csv_descriptor'
                                             elsif @customer.uses?(:csv_descriptor)
                                               'use_csv_descriptor'
                                             else
                                               'period_options'
                                             end
                                           when 'csv_descriptor'
                                             'use_csv_descriptor'
                                           when 'use_csv_descriptor'
                                             'period_options'
                                           when 'period_options'
                                             if @organization.uses_softwares?
                                               'softwares_selection'
                                             elsif @customer.subscription.is_package?('pre_assignment_option')
                                               'compta_options'
                                             else
                                               'subscription'
                                             end
                                           when 'softwares_selection'
                                             if @customer.subscription.is_package?('pre_assignment_option')
                                               'compta_options'
                                             else
                                               'subscription'
                                             end
                                           when 'compta_options'
                                             'subscription'
                                           when 'subscription'
                                             'subscription'
                                           when 'account'
                                             'account'
    end
    @customer.save
    redirect_to step_path(@customer.current_configuration_step)
  end

  def current_step?
    case @customer.current_configuration_step
    when 'account'
      false
    when 'subscription'
      controller_name == 'subscriptions'
    when 'softwares_selection'
      controller_name == 'customers' && action_name.in?(%w[edit_softwares_selection update_softwares_selection])
    when 'compta_options'
      controller_name == 'customers' && action_name.in?(%w[edit_compta_options update_compta_options])
    when 'period_options'
      controller_name == 'customers' && action_name.in?(%w[edit_period_options update_period_options])
    when 'ibiza'
      controller_name == 'customers' && action_name.in?(%w[edit_ibiza update_ibiza])
    when 'use_csv_descriptor'
      controller_name == 'use_csv_descriptors'
    when 'csv_descriptor'
      controller_name == 'csv_descriptors'
    when 'accounting_plans'
      controller_name == 'accounting_plans'
    when 'vat_accounts'
      controller_name == 'vat_accounts'
    when 'journals'
      controller_name.in?(%w[journals list_journals])
    when 'order_paper_set'
      controller_name == 'orders' && ((action_name.in?(%w[new create]) && params[:order][:type] == 'paper_set') || action_name.in?(%w[edit update]))
    when 'order_dematbox'
      controller_name == 'orders' && ((action_name.in?(%w[new create]) && params[:order][:type] == 'dematbox') || action_name.in?(%w[edit update]))
    when 'ged'
      controller_name == 'customers' && action_name.in?(%w[edit_knowings_options update_knowings_options])
    end
  end

  def last_step?
    case @customer.current_configuration_step
    when 'journals'
      !@customer.subscription.is_package?('mail_option') &&
        !@customer.is_dematbox_authorized &&
        !@organization.knowings.try(:configured?)
    when 'order_paper_set'
      !@customer.is_dematbox_authorized &&
        !@organization.knowings.try(:configured?)
    when 'order_dematbox'
      !@organization.knowings.try(:configured?)
    when 'ged'
      true
    else
      false
    end
  end

  def step_path(step)
    case step
    when 'account'
      nil
    when 'subscription'
      edit_account_organization_customer_subscription_path(@organization, @customer)
    when 'softwares_selection'
      edit_softwares_selection_account_organization_customer_path(@organization, @customer)
    when 'compta_options'
      edit_compta_options_account_organization_customer_path(@organization, @customer)
    when 'period_options'
      edit_period_options_account_organization_customer_path(@organization, @customer)
    when 'ibiza'
      edit_ibiza_account_organization_customer_path(@organization, @customer)
    when 'use_csv_descriptor'
      edit_account_organization_customer_use_csv_descriptor_path(@organization, @customer)
    when 'csv_descriptor'
      edit_account_organization_customer_csv_descriptor_path(@organization, @customer)
    when 'accounting_plans'
      account_organization_customer_accounting_plan_path(@organization, @customer)
    when 'vat_accounts'
      account_organization_customer_accounting_plan_vat_accounts_path(@organization, @customer)
    when 'journals'
      account_organization_customer_list_journals_path(@organization, @customer)
    when 'order_paper_set'
      order = @customer.orders.paper_sets.pending.first
      if order
        edit_account_organization_customer_order_path(@organization, @customer, order)
      else
        new_account_organization_customer_order_path(@organization, @customer, order: { type: 'paper_set' })
      end
    when 'order_dematbox'
      order = @customer.orders.dematboxes.pending.first
      if order
        edit_account_organization_customer_order_path(@organization, @customer, order)
      else
        new_account_organization_customer_order_path(@organization, @customer, order: { type: 'dematbox' })
      end
    when 'ged'
      edit_knowings_options_account_organization_customer_path(@organization, @customer)
    end
  end

  included do
    helper_method :last_step?
  end
end
