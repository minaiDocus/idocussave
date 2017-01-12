# -*- encoding : UTF-8 -*-
class Account::RetrieverController < Account::AccountController
  layout 'layouts/account/retrievers'

  before_filter :verify_rights

  private

  def verify_rights
    unless @user.options.is_retriever_authorized && @user.organization.is_active
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to root_path
    end
  end
end
