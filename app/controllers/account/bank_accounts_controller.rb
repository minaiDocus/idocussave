# -*- encoding : UTF-8 -*-
class Account::BankAccountsController < Account::RetrieverController
  def index
    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @account.retrievers.find(bank_account_contains[:retriever_id])
      @retriever.ready if @retriever && @retriever.waiting_selection?
    end
    @bank_accounts = @account.bank_accounts
    @is_filter_empty = bank_account_contains.empty?
  end

  def update_multiple
    bank_accounts = @account.bank_accounts
    if bank_account_ids.is_a?(Array)
      selected_bank_accounts = @account.bank_accounts.where(id: bank_account_ids)
      unselected_bank_accounts = @account.bank_accounts.where.not(id: bank_account_ids)
      selected_bank_accounts.update_all(is_used: true)
      unselected_bank_accounts.update_all(is_used: false)
      selected_bank_accounts.map(&:retriever).compact.uniq.each do |retriever|
        retriever.ready if retriever.waiting_selection?
      end
      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_bank_accounts_path(bank_account_contains: params[:bank_account_contains])
  end

private

  def bank_account_contains
    search_terms(params[:bank_account_contains])
  end
  helper_method :bank_account_contains

  def bank_account_ids
    params[:bank_account_ids].reject(&:blank?)
  end
end
