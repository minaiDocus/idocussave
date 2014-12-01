# -*- encoding : UTF-8 -*-
class Account::VatAccountsController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :load_accounting_plan
  before_filter :verify_rights

  def index
    @vat_accounts = @accounting_plan.vat_accounts
  end

  def edit_multiple
  end

  def update_multiple
    if @accounting_plan.update_attributes(accounting_plan_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_accounting_plan_vat_accounts_path(@organization, @customer)
    else
      render action: 'edit_multiple'
    end
  end

private
  def load_customer
    @customer = customers.find_by_slug params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, params[:customer_id]) unless @customer
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
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def accounting_plan_params
    params.require(:accounting_plan).permit(:vat_accounts_attributes)
  end
end
