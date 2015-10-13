# -*- encoding : UTF-8 -*-
class Account::BankAccountsController < Account::FiduceoController
  def index
    if bank_account_contains && bank_account_contains[:retriever_id]
      @retriever = @user.fiduceo_retrievers.find(bank_account_contains[:retriever_id])
      @retriever.schedule if @retriever && @retriever.wait_selection?
    end
    @bank_accounts = BankAccountService.new(@user, @retriever).bank_accounts
    @is_filter_empty = bank_account_contains.empty?
  end

  def update_multiple
    bank_accounts = BankAccountService.new(@user).bank_accounts
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
        collaborators = @user.groups.map(&:collaborators).flatten
        collaborators = [@user.organization.leader] if collaborators.empty?
        collaborators.each do |collaborator|
          BankAccount.notify(collaborator.id.to_s, @user.id.to_s, added_bank_accounts.map(&:id).map(&:to_s))
        end
      end
      flash[:success] = 'Modifié avec succès.'
    end
    redirect_to account_bank_accounts_path(bank_account_contains: bank_account_contains)
  end

private

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
