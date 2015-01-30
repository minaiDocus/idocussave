# -*- encoding : UTF-8 -*-
class Account::Organization::FiduceoController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_rights

private

  def load_customer
    @customer = customers.find_by_slug params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, params[:id]) unless @customer
  end

  def verify_rights
    unless (is_leader? || @user.can_manage_customers?) && @customer.active? && @customer.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end
end
