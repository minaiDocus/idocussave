# -*- encoding : UTF-8 -*-
class Account::BankAccountsController < Account::RetrieverController
  def index
    fetch_remote_accounts

    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @account.retrievers.find(bank_account_contains[:retriever_id])
      @retriever.ready if @retriever && @retriever.waiting_selection?
    end
    @bank_accounts = @account.bank_accounts
    @is_filter_empty = bank_account_contains.empty?
  end

  def update_multiple
    if params[:bank_account_ids].is_a?(Array)
      params[:bank_account_ids] = params[:bank_account_ids].reject { |item| item.blank? }

      selected_bank_accounts = @account.bank_accounts.where(id: params[:bank_account_ids])
      unselected_bank_accounts = @account.bank_accounts.where.not(id: params[:bank_account_ids])

      selected_bank_accounts.update_all(is_used: true)
      unselected_bank_accounts.update_all(is_used: false)

      selected_bank_accounts.map(&:retriever).compact.uniq.each do |retriever|
        retriever.ready if retriever.waiting_selection?
      end

      activate_selected_accounts selected_bank_accounts

      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_bank_accounts_path(bank_account_contains: params[:bank_account_contains])
  end

private

  #TEMP fix of disable accounts budgea (according to DSP2)
  def client
    return nil unless @account.budgea_account
    @client ||= Budgea::Client.new @account.budgea_account.access_token
  end

  def fetch_remote_accounts
    if @account.budgea_account
      @account.retrievers.each do |retriever|
        remote_accounts = client.get_all_accounts retriever.budgea_id
        if client.response.code == 200 && client.error_message.nil?
          remote_accounts.each do |account|
            bank_account = @account.bank_accounts.where(
              'api_id = ? OR (name = ? AND number = ?)',
              account['id'],
              account['name'],
              account['number']
            ).first

            unless bank_account
              bank_account                   = BankAccount.new
              bank_account.user              = @account
              bank_account.retriever         = retriever
              bank_account.api_id            = account['id']
              bank_account.bank_name         = retriever.service_name
              bank_account.name              = account['name']
              bank_account.number            = account['number']
              bank_account.type_name         = account['type']
              bank_account.original_currency = account['currency']
              bank_account.save
            end
          end
        end
      end
    end
  end

  def activate_selected_accounts(banks)
    if @account.budgea_account
      banks.each do |bank|
        client.activate_account(bank.retriever.budgea_id, bank.api_id) if(bank.reload)
      end
    end
  end
  #TEMP fix

  def bank_account_contains
    search_terms(params[:bank_account_contains])
  end
  helper_method :bank_account_contains
end
