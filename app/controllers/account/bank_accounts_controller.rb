# -*- encoding : UTF-8 -*-
class Account::BankAccountsController < Account::FiduceoController
  # GET /account/bank_accounts
  def index
    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @user.fiduceo_retrievers.find()

      @retriever.schedule if @retriever && @retriever.wait_selection?
    end

    @bank_accounts = BankAccountService.new(@user, @retriever).bank_accounts

    @is_filter_empty = bank_account_contains.empty?
  end


  # PUT /account/bank_accounts/update_multiple
  def update_multiple
    bank_accounts = BankAccountService.new(@user).bank_accounts

    if params[:bank_accounts].is_a?(Hash) && params[:bank_accounts].any?
      UpdateBankAccount.update_multiple(bank_accounts, params)

      flash[:success] = 'Modifié avec succès.'
    end

    redirect_to account_bank_accounts_path(bank_account_contains: bank_account_contains)
  end


  private


  def bank_account_contains
    search_terms(params[:bank_account_contains])
  end
  helper_method :bank_account_contains
end
