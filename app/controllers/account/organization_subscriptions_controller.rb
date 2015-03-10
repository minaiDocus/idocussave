# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_resources

  def edit
  end

  def update
    subscription_form = SubscriptionForm.new(@subscription, @user)
    if subscription_form.submit(scan_subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'subscription')
    else
      render 'edit'
    end
  end

  def select_options
  end

  def propagate_options
    _params = scan_subscription_options_params
    if @subscription.update_attributes(_params)
      customer_ids = params[:scan_subscription][:customer_ids] - [''] rescue []
      customers = @organization.customers.where(:_id.in => customer_ids)
      if customer_ids.size == customers.size
        scan_subscriptions = customers.map do |customer|
          customer.find_or_create_scan_subscription
        end
        Scan::Subscription.where(:_id.in => scan_subscriptions.map(&:id)).update_all(_params)
        periods = scan_subscriptions.map(&:current_period)
        Scan::Period.where(:_id.in => periods.map(&:id)).update_all(_params)
        Scan::Period.without_callback :save, :before, :update_information do
          periods.map(&:update_price!)
        end
        flash[:success] = 'Propagé avec succès.'
        redirect_to account_organization_path(@organization, tab: 'subscription')
      else
        render 'select_options'
      end
    else
      render 'select_options'
    end
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_resources
    @subscription = @organization.find_or_create_subscription
    @products     = Product.by_position
    @options      = @subscription.options.entries
  end

  def scan_subscription_params
    params.require(:scan_subscription).permit(:period_duration, :product)
  end

  def scan_subscription_options_params
    _params = params.require(:scan_subscription).permit(
      :max_sheets_authorized,
      :max_upload_pages_authorized,
      :max_dematbox_scan_pages_authorized,
      :max_preseizure_pieces_authorized,
      :max_expense_pieces_authorized,
      :max_paperclips_authorized,
      :max_oversized_authorized,
      :unit_price_of_excess_sheet,
      :unit_price_of_excess_upload,
      :unit_price_of_excess_dematbox_scan,
      :unit_price_of_excess_preseizure,
      :unit_price_of_excess_expense,
      :unit_price_of_excess_paperclips,
      :unit_price_of_excess_oversized
    )
    _params.each { |k,v| _params[k] = v.to_i }
    _params
  end
end
