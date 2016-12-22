# -*- encoding : UTF-8 -*-
class Account::Organization::BankAccountsController < Account::Organization::FiduceoController
  before_filter :load_bank_account, except: %w(index update_multiple)

  def index
    bank_account_contains = search_terms(params[:bank_account_contains])

    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @customer.fiduceo_retrievers.find(bank_account_contains[:retriever_id])

      @retriever.schedule if @retriever && @retriever.wait_selection?
    end

    @bank_accounts = BankAccountService.new(@customer, @retriever).bank_accounts
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/bank_accounts/:id/edit
  def edit
  end


  # PUT /account/organizations/:organization_id/customers/:customer_id/bank_accounts/:id
  def update
    if UpdateBankAccount.execute(@bank_account, bank_account_params)

      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_customer_path(@organization, @customer, tab: 'bank_accounts')
    else
      render 'edit'
    end
  end


  # POST /account/organizations/:organization_id/customers/:customer_id/bank_accounts/update_multiple
  def update_multiple
    bank_accounts = BankAccountService.new(@customer).bank_accounts

    if UpdateBankAccount.execute_multiple(bank_accounts, params[:bank_accounts])
      flash[:success] = 'Modifié avec succès.'
    end

    redirect_to account_organization_customer_bank_accounts_path(@organization, @customer, bank_account_contains: bank_account_contains)
  end


  private

  def load_bank_account
    @bank_account = @customer.bank_accounts.find(params[:id])
  end


  def bank_account_params
    params.require(:bank_account).permit(:journal, :accounting_number, :temporary_account, :start_date)
  end
end
