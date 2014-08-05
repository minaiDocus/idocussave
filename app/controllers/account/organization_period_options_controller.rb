# -*- encoding : UTF-8 -*-
class Account::OrganizationPeriodOptionsController < Account::OrganizationController
  before_filter :verify_rights

  def edit
  end

  def update
    if @organization.update_attributes(organization_params)
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
    @organization.copy_to_users(params[:customers].presence || [])
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
