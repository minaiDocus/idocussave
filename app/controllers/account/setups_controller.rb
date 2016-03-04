# -*- encoding : UTF-8 -*-
class Account::SetupsController < Account::OrganizationController
  before_filter :load_customer

  def next
    if @customer.configured?
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      next_configuration_step
    end
  end

  def previous
    if @customer.configured?
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      previous_configuration_step
    end
  end

  def resume
    if @customer.last_configuration_step != nil
      step = @customer.current_configuration_step = @customer.last_configuration_step
      result = @customer.last_configuration_step = nil
      if step == 'compta_options'
        if @customer.subscription.is_pre_assignment_active
          result = 'compta_options'
        elsif @customer.options.upload_authorized?
          result = 'period_options'
        else
          result = 'journals'
        end
      elsif step == 'period_options'
        if @customer.options.upload_authorized?
          result = 'period_options'
        elsif @customer.subscription.is_pre_assignment_active
          if @organization.ibiza.try(:configured?)
            result = 'ibiza'
          else
            result = 'use_csv_descriptor'
          end
        else
          result = 'journals'
        end
      elsif step.in?(%w(ibiza use_csv_descriptor))
        if @customer.subscription.is_pre_assignment_active
          if @organization.ibiza.try(:configured?)
            result = 'ibiza'
          else
            result = 'use_csv_descriptor'
          end
        else
          result = 'journals'
        end
      elsif step == 'csv_descriptor'
        if @customer.subscription.is_pre_assignment_active
          if @customer.own_csv_descriptor_used?
            result = 'csv_descriptor'
          else
            result = 'use_csv_descriptor'
          end
        else
          result = 'journals'
        end
      elsif step.in?(%w(accounting_plans vat_accounts exercises))
        if @customer.subscription.is_pre_assignment_active
          if @organization.ibiza.try(:configured?)
            result = 'ibiza'
          else
            result = step
          end
        else
          result = 'journals'
        end
      elsif step == 'journals'
        result = 'journals'
      elsif step == 'order_paper_set'
        if @customer.subscription.is_mail_package_active && (@customer.orders.paper_sets.empty? || @customer.orders.paper_sets.pending.first)
          result = 'order_paper_set'
        elsif @customer.subscription.is_scan_box_package_active && (@customer.orders.dematboxes.empty? || @customer.orders.dematboxes.pending.first)
          result = 'order_dematbox'
        elsif @customer.subscription.is_retriever_package_active
          result = 'retrievers'
        else
          result = 'ged'
        end
      elsif step == 'order_dematbox'
        if @customer.subscription.is_scan_box_package_active && (@customer.orders.dematboxes.empty? || @customer.orders.dematboxes.pending.first)
          result = 'order_dematbox'
        elsif @customer.subscription.is_retriever_package_active
          result = 'retrievers'
        else
          result = 'ged'
        end
      elsif step == 'retrievers'
        if @customer.subscription.is_retriever_package_active
          result = 'retrievers'
        else
          result = 'ged'
        end
      else
        result = 'ged'
      end
      @customer.current_configuration_step = result
      @customer.save
      redirect_to step_path(@customer.current_configuration_step)
    else
      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end

  def complete_later
    unless @customer.configured?
      @customer.last_configuration_step = @customer.current_configuration_step
      @customer.current_configuration_step = nil
      @customer.save
    end
    redirect_to account_organization_customer_path(@organization, @customer)
  end
end
