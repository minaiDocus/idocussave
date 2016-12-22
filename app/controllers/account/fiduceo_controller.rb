# -*- encoding : UTF-8 -*-
class Account::FiduceoController < Account::AccountController
  layout 'layouts/account/retrievers'

  before_filter :verify_rights

  private

  def verify_rights
    unless @user.is_fiduceo_authorized && @user.organization.is_active
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to root_path
    end
  end
end
