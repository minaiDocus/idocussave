# frozen_string_literal: true

class Account::VatAccountsController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_accounting_plan
  before_action :verify_rights

  # GET /account/organizations/:organization_id/customers/:customer_id/accounting_plan/vat_accounts
  def index
    @vat_accounts = @accounting_plan.vat_accounts
  end

  # /account/organizations/:organization_id/customers/:customer_id/accounting_plan/vat_accounts/edit_multiple
  def edit_multiple; end

  # /account/organizations/:organization_id/customers/:customer_id/accounting_plan/update_multiple
  def update_multiple
    modified = params[:accounting_plan].present? ? @accounting_plan.update(accounting_plan_params) : true

    respond_to do |format|
      format.html {
        if modified
          flash[:success] = 'Modifié avec succès.'
          redirect_to account_organization_customer_accounting_plan_vat_accounts_path(@organization, @customer)
        else
          render :edit_multiple
        end
      }
      format.json {
        if params[:destroy].present? && params[:id].present?
          @accounting_plan.vat_accounts.find(params[:id]).destroy
          vat_account = nil
        elsif params[:accounting_plan][:vat_accounts_attributes][:id].present?
          vat_account = @accounting_plan.vat_accounts.find(params[:accounting_plan][:vat_accounts_attributes][:id])
        else
          vat_account = AccountingPlanVatAccount.unscoped.where(accounting_plan_id: @accounting_plan.id).order(id: :desc).first
        end

        render json: { account: vat_account  }, status: 200
      }
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
    unless (@user.leader? || @user.manage_customers)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def accounting_plan_params
    { vat_accounts_attributes: params[:accounting_plan][:vat_accounts_attributes].permit! }
  end
end
