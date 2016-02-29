# -*- encoding : UTF-8 -*-
class Account::UseCsvDescriptorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :redirect_to_current_step

  def edit
  end

  def update
    if @customer.update(user_params)
      next_configuration_step
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization) || @organization.is_csv_descriptor_used
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def user_params
    params.require(:user).permit({ options_attributes: [:is_own_csv_descriptor_used] })
  end
end
