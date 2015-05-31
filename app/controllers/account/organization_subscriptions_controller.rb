# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_resources

  def edit
  end

  def update
    subscription_form = SubscriptionForm.new(@subscription, @user, request)
    if subscription_form.submit(subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'subscription')
    else
      render 'edit'
    end
  end

  def select_options
  end

  def propagate_options
    _params = subscription_options_params
    if @subscription.update(_params)
      ids = params[:subscription][:customer_ids] - [''] rescue []
      registered_ids = @organization.customers.where(:_id.in => ids).distinct(:_id)
      if ids.size == registered_ids.size
        subscriptions = Subscription.where(:user_id.in => ids)
        subscription_ids = subscriptions.distinct(:_id)
        subscriptions.update_all(_params)
        periods = Period.where(
          :subscription_id.in => subscription_ids,
          :start_at.lte => Time.now,
          :end_at.gte => Time.now
        )
        periods.each do |period|
          period.update(_params)
          UpdatePeriodPriceService.new(period).execute
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

  def subscription_params
    {
      period_duration: params[:subscription][:period_duration],
      product:         params[:subscription][:product]
    }.with_indifferent_access
  end

  def subscription_options_params
    _params = params.require(:subscription).permit(
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
