# frozen_string_literal: true

class Account::BankAccountsController < Account::RetrieverController
  before_action :load_budgea_config
  before_action :verif_account

  def index
    if bank_account_contains && bank_account_contains[:retriever_budgea_id]
      @retriever = @account.retrievers.find_by_budgea_id(bank_account_contains[:retriever_budgea_id])
      @retriever.ready if @retriever&.waiting_selection?
    end

    @bank_accounts = @account.retrievers.collect(&:bank_accounts).flatten! || []
    @is_filter_empty = bank_account_contains.empty?
  end

  private

  def bank_account_contains
    search_terms(params[:bank_account_contains])
  end
  helper_method :bank_account_contains

  def bank_account_ids
    params[:bank_account_ids].reject(&:blank?)
  end

  def load_budgea_config
    bi_config = {
      url: "https://#{Budgea.config.domain}/2.0",
      c_id: Budgea.config.client_id,
      c_ps: Budgea.config.client_secret,
      c_ky: Budgea.config.encryption_key ? Base64.encode64(Budgea.config.encryption_key.to_json.to_s) : '',
      proxy: Budgea.config.proxy
    }.to_json
    @bi_config = Base64.encode64(bi_config.to_s)
  end

  def verif_account
    if @account.nil?
      redirect_to account_retrievers_path
    end
  end
end
