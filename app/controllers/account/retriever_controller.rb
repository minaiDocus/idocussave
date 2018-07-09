# -*- encoding : UTF-8 -*-
class Account::RetrieverController < Account::AccountController
  layout 'layouts/account/retrievers'

  before_action :verify_rights
  before_action :load_account

private

  def verify_rights
    unless accounts.any? && @user.organization.is_active
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_account
    account_id = params[:account_id].presence || session[:retrievers_account_id].presence || 'all'

    @account = nil
    unless account_id == 'all'
      @account = accounts.where(id: account_id).first || accounts.first
    end

    session[:retrievers_account_id] = account_id
  end

  def accounts
    super.joins(:options).where('user_options.is_retriever_authorized = ?', true)
  end
end
