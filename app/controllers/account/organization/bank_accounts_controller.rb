# -*- encoding : UTF-8 -*-
class Account::Organization::BankAccountsController < Account::Organization::RetrieverController
  before_filter :load_bank_account, except: %w(index update_multiple)

  def index
    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @customer.retrievers.find(bank_account_contains[:retriever_id])
      @retriever.ready if @retriever && @retriever.waiting_selection?
    end
    @bank_accounts = @customer.bank_accounts
  end

  def edit
  end

  def update
    @bank_account.assign_attributes(bank_account_params)
    changes = @bank_account.changes.dup
    @bank_account.is_for_pre_assignment = true
    if @bank_account.save
      @bank_account.operations.where(is_locked: true, :date.gte => @bank_account.start_date).update_all(is_locked: false)
      UpdatePreseizureAccountNumbers.async_execute(@bank_account.id.to_s, changes)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'bank_accounts')
    else
      render 'edit'
    end
  end

  def update_multiple
    bank_accounts = @user.bank_accounts
    if params[:bank_account_ids].is_a?(Array)
      selected_bank_accounts = @user.bank_accounts.where(:_id.in => params[:bank_account_ids])
      unselected_bank_accounts = @user.bank_accounts.where(:_id.nin => params[:bank_account_ids])
      selected_bank_accounts.update_all(is_used: true)
      unselected_bank_accounts.update_all(is_used: false)
      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_organization_customer_bank_accounts_path(@organization, @customer, bank_account_contains: bank_account_contains)
  end

private

  def load_bank_account
    @bank_account = @customer.bank_accounts.find params[:id]
  end

  def bank_account_params
    params.require(:bank_account).permit(:journal, :accounting_number, :temporary_account, :start_date)
  end

  def bank_account_contains
    @contains ||= {}
    if params[:bank_account_contains] && @contains.blank?
      @contains = params[:bank_account_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :bank_account_contains
end
