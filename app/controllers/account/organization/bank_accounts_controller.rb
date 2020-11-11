# frozen_string_literal: true

class Account::Organization::BankAccountsController < Account::Organization::RetrieverController
  before_action :load_bank_account, except: %w[index update_multiple]
  before_action :bank_setting_retriever

  def index
    redirect_to account_retrievers_path(account_id: @customer.id)
    # fetch_remote_accounts

    # bank_account_contains = search_terms(params[:bank_account_contains])
    # if bank_account_contains && bank_account_contains[:retriever_id]
    #   @retriever = @customer.retrievers.find(bank_account_contains[:retriever_id])
    #   @retriever.ready if @retriever&.waiting_selection?
    # end
    # @bank_accounts = @customer.retrievers.collect(&:bank_accounts).flatten! || []
  end

  def edit; end

  def update
    @bank_account.assign_attributes(bank_account_params)
    changes = @bank_account.changes.dup
    @bank_account.is_for_pre_assignment = true
    start_date_changed = @bank_account.start_date_changed?
    if @bank_account.save
      if start_date_changed && @bank_account.start_date.present?
        @bank_account.operations.where('is_locked = ? and is_coming = ? and date >= ?', true, false, @bank_account.start_date).update_all(is_locked: false)
      end
      PreAssignment::UpdateAccountNumbers.delay.execute(@bank_account.id.to_s, changes)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'bank_accounts')
    else
      render 'edit'
    end
  end

  def update_multiple
    if params[:bank_account_ids].is_a?(Array)
      params[:bank_account_ids] = params[:bank_account_ids].reject { |item| item.blank? }

      selected_bank_accounts = @customer.bank_accounts.where(id: params[:bank_account_ids])
      unselected_bank_accounts = @customer.bank_accounts.where.not(id: params[:bank_account_ids])

      selected_bank_accounts.update_all(is_used: true)
      unselected_bank_accounts.update_all(is_used: false)

      selected_bank_accounts.map(&:retriever).compact.uniq.each do |retriever|
        retriever.ready if retriever.waiting_selection?
      end

      activate_selected_accounts selected_bank_accounts

      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_organization_customer_bank_accounts_path(@organization, @customer, bank_account_contains: params[:bank_account_contains])
  end

  private

  # TEMP fix of disable accounts budgea (according to DSP2)
  def client
    return nil unless @customer.budgea_account

    @client ||= Budgea::Client.new @customer.budgea_account.access_token
  end

  def fetch_remote_accounts
    if @customer.budgea_account
      @customer.retrievers.each do |retriever|
        remote_accounts = client.get_all_accounts retriever.budgea_id
        next unless client.response.status == 200 && client.error_message.nil?

        remote_accounts.each do |account|
          bank_account = @customer.bank_accounts.where(
            'api_id = ? OR (name = ? AND number = ?)',
            account['id'],
            account['name'],
            account['number']
          ).first

          if bank_account
            bank_account.is_used = false unless bank_account.retriever

            bank_account.user              = @customer
            bank_account.retriever         = retriever
            bank_account.api_id            = account['id']
            bank_account.api_name          = 'budgea'
            bank_account.name              = account['name']
            bank_account.type_name         = account['type']
            bank_account.original_currency = account['currency']
            bank_account.save if bank_account.changed?
          else
            bank_account                   = BankAccount.new
            bank_account.user              = @customer
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

  def activate_selected_accounts(banks)
    if @customer.budgea_account
      banks.each do |bank|
        if bank.reload
          client.activate_account(bank.retriever.budgea_id, bank.api_id)
        end
      end
    end
  end
  # TEMP fix

  def load_bank_account
    @bank_account = @customer.bank_accounts.find(params[:id])
  end

  def bank_account_params
    params.require(:bank_account).permit(:journal, :currency, :accounting_number, :foreign_journal, :temporary_account, :start_date, :lock_old_operation, :permitted_late_days)
  end

  def bank_setting_retriever
    redirect_to account_bank_settings_path({account_id: @customer.id})
  end
end