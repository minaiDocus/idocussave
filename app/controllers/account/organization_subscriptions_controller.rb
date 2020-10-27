# frozen_string_literal: true

class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_subscription

  # GET /account/organizations/:organization_id/organization_subscription/edit
  def edit; end

  # PUT /account/organizations/:organization_id/organization_subscription
  def update
    if @subscription.update(subscription_params)
      Billing::UpdatePeriod.new(@subscription.current_period).execute
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'subscription')
    else
      render :edit
    end
  end

  # GET /account/organizations/:organization_id/organization_subscription/select_options
  def select_options; end

  # PUT /account/organizations/:organization_id/organization_subscription/propagate_options
  def propagate_options
    _params = subscription_quotas_params

    if @subscription.update(_params)
      ids = begin
              params[:subscription][:customer_ids] - ['']
            rescue StandardError
              []
            end

      registered_ids = @organization.customers.where(id: ids).pluck(:id)

      if ids.size == registered_ids.size
        subscriptions = Subscription.where(user_id: ids)

        subscriptions.update_all(_params.to_s)

        periods = Period.where(subscription_id: subscriptions.map(&:id)).where('start_date <= ? AND end_date >= ?', Date.today, Date.today)

        periods.each do |period|
          period.update(_params)
          Billing::UpdatePeriodPrice.new(period).execute
        end

        flash[:success] = 'Propagé avec succès.'

        redirect_to account_organization_path(@organization, tab: 'subscription')
      else
        render :select_options
      end
    else
      render :select_options
    end
  end

  private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def load_subscription
    @subscription = @organization.find_or_create_subscription
  end

  def subscription_params
    params.require(:subscription).permit(option_ids: [])
  end

  def subscription_quotas_params
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

    _params.each { |k, v| _params[k] = v.to_i }
    _params
  end
end
