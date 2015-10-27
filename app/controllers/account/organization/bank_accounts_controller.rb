# -*- encoding : UTF-8 -*-
class Account::Organization::BankAccountsController < Account::Organization::FiduceoController
  before_filter :load_bank_account, :except => [:index, :update_multiple]

  def index
    @bank_accounts = search(bank_account_contains)
  end

  def edit
  end

  def update
    @bank_account.assign_attributes(bank_account_params)
    changes = @bank_account.changes.dup
    if @bank_account.save
      @bank_account.operations.where(is_locked: true).update_all(is_locked: false)
      UpdatePreseizureAccountNumbers.async_execute(@bank_account.id.to_s, changes)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'bank_accounts')
    else
      render 'edit'
    end
  end

  def update_multiple
    bank_accounts = BankAccountService.new(@customer).bank_accounts
    if params[:bank_accounts].is_a?(Hash) && params[:bank_accounts].any?
      added_bank_accounts = []
      params[:bank_accounts].each do |fiduceo_id, value|
        bank_account = bank_accounts.select { |e| e.fiduceo_id == fiduceo_id }.first
        if bank_account
          is_selected = value == '1'
          if !bank_account.persisted? && is_selected
            bank_account.save
            OperationService.update_bank_account(bank_account)
            added_bank_accounts << bank_account
          elsif bank_account.persisted? && !is_selected
            bank_account.destroy
          end
        end
      end
      if added_bank_accounts.any?
        collaborators = @customer.groups.map(&:collaborators).flatten
        collaborators = [@customer.organization.leader] if collaborators.empty?
        collaborators.each do |collaborator|
          BankAccount.notify(collaborator.id.to_s, @customer.id.to_s, added_bank_accounts.map(&:id).map(&:to_s))
        end
      end
      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_bank_accounts_path(bank_account_contains: bank_account_contains)
  end

private

  def load_bank_account
    @bank_account = @customer.bank_accounts.find params[:id]
  end

  def bank_account_params
    params.require(:bank_account).permit(:journal, :accounting_number, :temporary_account)
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

  def search(contains)
    bank_accounts = BankAccountService.new(@customer).bank_accounts
    bank_accounts = bank_accounts.where(retriever_id: contains[:retriever_id]) if contains[:retriever_id]
    bank_accounts
  end
end
