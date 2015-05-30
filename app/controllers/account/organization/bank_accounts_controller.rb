# -*- encoding : UTF-8 -*-
class Account::Organization::BankAccountsController < Account::Organization::FiduceoController
  before_filter :load_bank_account

  def edit
  end

  def update
    if @bank_account.update(bank_account_params)
      @bank_account.operations.where(is_locked: true).update_all(is_locked: false)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'bank_accounts')
    else
      render 'edit'
    end
  end

private

  def load_bank_account
    @bank_account = @customer.bank_accounts.find params[:id]
  end

  def bank_account_params
    params.require(:bank_account).permit(:journal, :accounting_number, :temporary_account)
  end
end
