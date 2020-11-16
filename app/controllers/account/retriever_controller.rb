# frozen_string_literal: true

class Account::RetrieverController < Account::AccountController
  layout 'layouts/account/retrievers'

  before_action :verify_rights
  before_action :load_account

  private

  def verify_rights
    unless (accounts.any? && @user.organization.is_active) || @user.organization.specific_mission
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_account
    if accounts.count == 1
      @account = accounts.first
      session[:retrievers_account_id] = @account.id
    else
      account_id = params[:account_id].presence || session[:retrievers_account_id].presence || 'all'
      @account = nil

      if account_id != 'all'
        @account = accounts.where(id: account_id).first || accounts.first
      end
      session[:retrievers_account_id] = account_id
    end
  end

  def accounts
    if @user.organization.specific_mission
      super
    else
      super.joins(:options).where('user_options.is_retriever_authorized = ?', true)
    end
  end
end
