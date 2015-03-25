# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :load_subscription
  before_filter :load_product
  before_filter :load_options

  def edit
  end

  def update
    subscription_form = SubscriptionForm.new(@subscription, @user, request)
    if subscription_form.submit(subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'subscription')
    else
      render action: 'edit'
    end
  end

private

  def subscription_params
    attributes = [:product]
    attributes << :period_duration unless Settings.is_subscription_lower_options_disabled
    if @user.is_admin
      attributes += [
        :max_sheets_authorized,
        :unit_price_of_excess_sheet,
        :max_upload_pages_authorized,
        :unit_price_of_excess_upload,
        :max_dematbox_scan_pages_authorized,
        :unit_price_of_excess_dematbox_scan,
        :max_preseizure_pieces_authorized,
        :unit_price_of_excess_preseizure,
        :max_expense_pieces_authorized,
        :unit_price_of_excess_expense,
        :max_paperclips_authorized,
        :unit_price_of_excess_paperclips,
        :max_oversized_authorized,
        :unit_price_of_excess_oversized
      ]
      params.require(:subscription).permit(*attributes)
    else
      params.require(:subscription).permit(*attributes)
    end
  end

  def load_customer
    @customer = customers.find_by_slug params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, params[:customer_id]) unless @customer
  end

  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_subscription
    @subscription = @customer.subscription
  end

  def load_product
    @products = Product.by_position
  end

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_options
    @options = @subscription.options.entries
  end
end
