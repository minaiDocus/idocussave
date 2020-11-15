# frozen_string_literal: true

class Account::Organization::RetrieverController < Account::OrganizationController
  before_action :load_customer
  before_action :redirect_to_current_step
  before_action :verify_rights

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end

  def verify_rights
    unless ((@user.leader? || @user.manage_customers) && @customer.active? && @customer.options.is_retriever_authorized && @customer.organization.is_active) || @customer.organization.specific_mission
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end
end
