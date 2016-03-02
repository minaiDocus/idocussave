# -*- encoding : UTF-8 -*-
class Account::OrganizationController < Account::AccountController
  layout 'organization'

  before_filter :verify_role
  before_filter :load_organization

protected

  def verify_role
    unless @user.is_prescriber
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def load_organization
    if @user.is_admin
      @organization = Organization.find_by_slug! params[:organization_id]
      raise Mongoid::Errors::DocumentNotFound.new(Organization, slug: params[:organization_id]) unless @organization
    elsif params[:organization_id] == @user.organization.slug
      @organization = @user.organization
    else
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def is_leader?
    @user == @organization.leader || @user.is_admin
  end
  helper_method :is_leader?

  def customers
    if @user.is_admin
      @organization.customers
    else
      @user.customers
    end
  end

  def customer_ids
    customers.map(&:id)
  end

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end

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
      if @customer.subscription.is_pre_assignment_active
        'compta_options'
      elsif @customer.options.is_upload_authorized
        'period_options'
      else
        'journals'
      end
    when 'compta_options'
      'period_options'
    when 'period_options'
      if @customer.subscription.is_pre_assignment_active
        if @organization.ibiza.try(:configured?)
          'ibiza'
        else
          'use_csv_descriptor'
        end
      else
        'journals'
      end
    when 'use_csv_descriptor'
      if @customer.options.is_own_csv_descriptor_used
        'csv_descriptor'
      else
        'accounting_plans'
      end
    when 'csv_descriptor'
      'accounting_plans'
    when 'accounting_plans'
      'vat_accounts'
    when 'vat_accounts'
      'exercises'
    when 'exercises'
      'journals'
    when 'ibiza'
      'journals'
    when 'journals'
      if @customer.subscription.is_mail_package_active
        'order_paper_set'
      elsif @customer.subscription.is_scan_box_package_active
        'order_dematbox'
      elsif @customer.subscription.is_retriever_package_active
        'retrievers'
      elsif @organization.knowings.try(:configured?)
        'ged'
      else
        nil
      end
    when 'order_paper_set'
      if @customer.subscription.is_scan_box_package_active
        'order_dematbox'
      elsif @customer.subscription.is_retriever_package_active
        'retrievers'
      elsif @organization.knowings.try(:configured?)
        'ged'
      else
        nil
      end
    when 'order_dematbox'
      if @customer.subscription.is_retriever_package_active
        'retrievers'
      elsif @organization.knowings.try(:configured?)
        'ged'
      else
        nil
      end
    when 'retrievers'
      if @organization.knowings.try(:configured?)
        'ged'
      else
        nil
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

  def current_step?
    case @customer.current_configuration_step
    when 'account'
      false
    when 'subscription'
      controller_name == 'subscriptions'
    when 'compta_options'
      controller_name == 'customers' && action_name.in?(%w(edit_compta_options update_compta_options))
    when 'period_options'
      controller_name == 'customers' && action_name.in?(%w(edit_period_options update_period_options))
    when 'ibiza'
      controller_name == 'customers' && action_name.in?(%w(edit_ibiza update_ibiza))
    when 'use_csv_descriptor'
      controller_name == 'use_csv_descriptors'
    when 'csv_descriptor'
      controller_name == 'csv_descriptors'
    when 'accounting_plans'
      controller_name == 'accounting_plans'
    when 'vat_accounts'
      controller_name == 'vat_accounts'
    when 'exercises'
      controller_name == 'exercises'
    when 'journals'
      controller_name.in?(%w(journals list_journals))
    when 'order_paper_set'
      controller_name == 'orders' && action_name.in?(%w(new create)) && params[:order][:type] == 'paper_set'
    when 'order_dematbox'
      controller_name == 'orders' && action_name.in?(%w(new create)) && params[:order][:type] == 'dematbox'
    when 'retrievers'
      controller_name.in?(%w(retrievers retriever_transactions retrieved_banking_operations retrieved_documents bank_accounts')) && params[:customer_id].present?
    when 'ged'
      controller_name == 'customers' && action_name.in?(%w(edit_knowings_options update_knowings_options))
    end
  end

  def last_step?
    case @customer.current_configuration_step
    when 'journals'
      !@customer.subscription.is_mail_package_active &&
      !@customer.subscription.is_scan_box_package_active &&
      !@customer.subscription.is_retriever_package_active &&
      !@organization.knowings.try(:configured?)
    when 'order_paper_set'
      !@customer.subscription.is_scan_box_package_active &&
      !@customer.subscription.is_retriever_package_active &&
      !@organization.knowings.try(:configured?)
    when 'order_dematbox'
      !@customer.subscription.is_retriever_package_active &&
      !@organization.knowings.try(:configured?)
    when 'retrievers'
      !@organization.knowings.try(:configured?)
    when 'ged'
      true
    else
      false
    end
  end
  helper_method :last_step?

  def step_path(step)
    case step
    when 'account'
      nil
    when 'subscription'
      edit_account_organization_customer_subscription_path(@organization, @customer)
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
    when 'exercises'
      account_organization_customer_exercises_path(@organization, @customer)
    when 'journals'
      account_organization_customer_list_journals_path(@organization, @customer)
    when 'order_paper_set'
      new_account_organization_customer_order_path(@organization, @customer, order: { type: 'paper_set' })
    when 'order_dematbox'
      new_account_organization_customer_order_path(@organization, @customer, order: { type: 'dematbox' })
    when 'retrievers'
      account_organization_customer_fiduceo_retrievers_path(@organization, @customer)
    when 'ged'
      edit_knowings_options_account_organization_customer_path(@organization, @customer)
    end
  end
end
