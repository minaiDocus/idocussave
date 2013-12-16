# -*- encoding : UTF-8 -*-
class Account::BankAccountsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :load_bank_account, except: 'index'

  def index
    @bank_accounts = BankAccountService.new(@customer).bank_accounts
  end

  def edit
  end

  def update
    if @bank_account.update_attributes(bank_account_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_bank_accounts_path(@customer)
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def load_customer
    @customer = @user.customers.find params[:customer_id]
  end

  def load_bank_account
    @bank_account = BankAccountService.new(@customer).find(params[:id])
  end

  def bank_account_params
    params.require(:bank_account).permit(:number, :journal, :accounting_number)
  end
end
