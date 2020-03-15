# frozen_string_literal: true

class Account::BankSettingsController < Account::RetrieverController
  before_action :load_bank_account, except: %w[index]
  before_action :verif_account

  def index
    @bank_accounts = @account.retrievers.collect(&:bank_accounts).flatten! || []
    if bank_account_contains
      @bank_accounts = @account.bank_accounts.used
      @bank_accounts = @bank_accounts.where('bank_name LIKE ?', "%#{search_by('bank_name')}%") if search_by('bank_name').present?
      @bank_accounts = @bank_accounts.where('name LIKE ?', "%#{search_by('name')}%") if search_by('name').present?
      @bank_accounts = @bank_accounts.where('number LIKE ?', "%#{search_by('number')}%") if search_by('number').present?
      @bank_accounts = @bank_accounts.where('journal LIKE ?', "%#{search_by('journal')}%") if search_by('journal').present?
      @bank_accounts = @bank_accounts.where('accounting_number LIKE ?', "%#{search_by('accounting_number')}%") if search_by('accounting_number').present?
    end
    @bank_accounts
  end

  def edit; end

  def update
    @bank_account.assign_attributes(bank_setting_params)
    changes = @bank_account.changes.dup
    @bank_account.is_for_pre_assignment = true
    start_date_changed = @bank_account.start_date_changed?
    if @bank_account.save
      if start_date_changed && @bank_account.start_date.present?
        @bank_account.operations.where('is_locked = ? and is_coming = ? and date >= ?', true, false, @bank_account.start_date).update_all(is_locked: false)
      end
      UpdatePreseizureAccountNumbers.delay.execute(@bank_account.id.to_s, changes)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_bank_settings_path({ account_id: @account.id })
    else
      render 'edit'
    end
  end

  private

  def bank_account_contains
    search_terms(params.try(:[], 'bank_account_contains').try(:[], 'bank_account'))
  end
  helper_method :bank_account_contains

  def search_by(field)
    bank_account_contains.try(:[], field)
  end

  def load_bank_account
    @bank_account = @account.bank_accounts.find(params[:id])
  end

  def bank_setting_params
    params.require(:bank_account).permit(:journal, :currency, :accounting_number, :foreign_journal, :temporary_account, :start_date, :lock_old_operation, :permitted_late_days)
  end

  def verif_account
    @customer = @account
    if @account.nil?
      redirect_to account_retrievers_path
    end
  end
end
