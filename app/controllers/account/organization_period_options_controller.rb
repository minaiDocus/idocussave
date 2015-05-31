# -*- encoding : UTF-8 -*-
class Account::OrganizationPeriodOptionsController < Account::OrganizationController
  before_filter :verify_rights

  def edit
  end

  def update
    if @organization.update(organization_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'period_options')
    else
      render 'edit'
    end
  end

  def select_propagation_options
    @customers = @organization.customers.active.asc(:code)
  end

  def propagate
    registered_ids = @organization.customers.active.map(&:id).map(&:to_s)
    valid_ids = (params[:customer_ids].presence || []).select do |customer_id|
      registered_ids.include? customer_id
    end
    User.where(:_id.in => valid_ids).update_all(
      authd_prev_period:            @organization.authd_prev_period,
      auth_prev_period_until_day:   @organization.auth_prev_period_until_day,
      auth_prev_period_until_month: @organization.auth_prev_period_until_month,
      updated_at:                   Time.now
    )
    flash[:success] = 'Options des périodes, propagés avec succès.'
    redirect_to account_organization_path(@organization, tab: 'period_options')
  end

private

  def verify_rights
    if action_name.in?(%w(edit update)) && (is_leader?)
      true
    elsif action_name.in?(%w(select_propagation_options propagate)) && @user.is_admin
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
