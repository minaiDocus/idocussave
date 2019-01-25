# -*- encoding : UTF-8 -*-
class Account::VatAccountsController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :redirect_to_current_step
  before_filter :load_accounting_plan
  before_filter :verify_rights

  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan/vat_accounts
  def index
    @vat_accounts = @accounting_plan.vat_accounts
  end


  # /account/organizations/:organization_id/customers/:customer_id/accounting_plan/vat_accounts/edit_multiple
  def edit_multiple
  end


  # /account/organizations/:organization_id/customers/:customer_id/accounting_plan/update_multiple
  def update_multiple
    modified = params[:accounting_plan].present? ? @accounting_plan.update(accounting_plan_params) : true

    if modified
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_customer_accounting_plan_vat_accounts_path(@organization, @customer)
    else
      render :edit_multiple
    end
  end

  private


  def load_customer
    @customer = customers.find params[:customer_id]
  end


  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_accounting_plan
    @accounting_plan = @customer.accounting_plan
  end


  def verify_rights
    unless (@user.leader? || @user.manage_customers) && !@customer.uses_api_softwares?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def accounting_plan_params
    { vat_accounts_attributes: params[:accounting_plan][:vat_accounts_attributes].permit! }
  end
end
