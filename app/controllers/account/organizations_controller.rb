# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::OrganizationController
  before_filter :verify_rights, except: 'show'

  def show
    if @organization
      @members = @organization.customers.page(params[:page]).per(params[:per])
      @periods = ::Scan::Period.where(:user_id.in => @organization.customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
    end
  end

  def edit
  end

  def update
    if @organization
      if @organization.update_attributes(organization_params)
        flash[:success] = 'Modifié avec succès.'
        redirect_to account_organization_path
      else
        render 'edit'
      end
    end
  end

private

  def organization_params
    params.require(:organization).permit(:name,
                                         :description,
                                         :addresses_attributes,
                                         :authd_prev_period,
                                         :auth_prev_period_until_day,
                                         :auth_prev_period_until_month)
  end

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

end