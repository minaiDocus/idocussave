# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :load_subscription
  before_filter :load_product

  def edit
    @options = @subscription.product_option_orders.map(&:to_a)
  end

  def update
    prev_options = @subscription.product_option_orders.map(&:dup)
    @subscription.requester = @user
    if @subscription.update_attributes(scan_subscription_params)
      EvaluateSubscriptionService.execute(@subscription, @user, prev_options)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'subscription')
    else
      render action: 'edit'
    end
  end

private

  def scan_subscription_params
    if @user.is_admin
      params.require(:scan_subscription).permit(
        :max_sheets_authorized,
        :unit_price_of_excess_sheet,
        :max_upload_pages_authorized,
        :quantity_of_a_lot_of_upload,
        :price_of_a_lot_of_upload,
        :max_dematbox_scan_pages_authorized,
        :quantity_of_a_lot_of_dematbox_scan,
        :price_of_a_lot_of_dematbox_scan,
        :max_preseizure_pieces_authorized,
        :unit_price_of_excess_preseizure,
        :max_expense_pieces_authorized,
        :unit_price_of_excess_expense,
        :max_paperclips_authorized,
        :unit_price_of_excess_paperclips,
        :max_oversized_authorized,
        :unit_price_of_excess_oversized,
        :payment_type,
        :end_in,
        :period_duration,
        :product)
    else
      params.require(:scan_subscription).permit(:period_duration, :product)
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
    @subscription = @customer.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end
end
