# -*- encoding : UTF-8 -*-
class Account::Organization::FiduceoController < Account::OrganizationController
  before_filter :load_customer
  before_filter :redirect_to_current_step
  before_filter :verify_rights


  private


  def load_customer
    @customer = customers.find(params[:customer_id])
  end


  def verify_rights
    unless (is_leader? || @user.can_manage_customers?) && @customer.active? && @customer.is_fiduceo_authorized && @customer.organization.is_active
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path
    end
  end
end
