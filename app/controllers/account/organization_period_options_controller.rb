# frozen_string_literal: true

class Account::OrganizationPeriodOptionsController < Account::OrganizationController
  before_action :verify_rights

  # GET /account/organizations/:organization_id/period_options/edit
  def edit; end

  # PUT /account/organizations/:organization_id/period_options
  def update
    if @organization.update(organization_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'period_options')
    else
      render :edit
    end
  end

  # PUT /account/organizations/:organization_id/organization_subscription/propagate_options
  def select_propagation_options
    @customers = @organization.customers.active.order(code: :asc)
  end

  # POST /account/organizations/:organization_id/period_options/propagate
  def propagate
    registered_ids = @organization.customers.active.map(&:id).map(&:to_s)

    valid_ids = (params[:customer_ids].presence || []).select do |customer_id|
      registered_ids.include? customer_id
    end

    User.where(id: valid_ids).update_all(
      authd_prev_period: @organization.authd_prev_period,
      auth_prev_period_until_day: @organization.auth_prev_period_until_day,
      auth_prev_period_until_month: @organization.auth_prev_period_until_month,
      updated_at: Time.now
    )

    flash[:success] = 'Options des périodes, propagés avec succès.'

    redirect_to account_organization_path(@organization, tab: 'period_options')
  end

  private

  def verify_rights
    if action_name.in?(%w[edit update]) && @user.leader?
      true
    elsif action_name.in?(%w[select_propagation_options propagate]) && @user.is_admin
      true
    else
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def organization_params
    if @user.is_admin
      params.require(:organization).permit(
        :authd_prev_period,
        :auth_prev_period_until_day,
        :auth_prev_period_until_month
      )
    else
      params.require(:organization).permit(
        :authd_prev_period,
        :auth_prev_period_until_day
      )
    end
  end
end
