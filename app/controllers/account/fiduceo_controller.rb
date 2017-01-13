# -*- encoding : UTF-8 -*-
class Account::FiduceoController < Account::AccountController
  layout 'layouts/account/retrievers'

  before_filter :verify_rights
  before_filter :redirect_to_root

  private

  def verify_rights
    unless @user.is_fiduceo_authorized && @user.organization.is_active
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to root_path
    end
  end

  def redirect_to_root
    flash[:notice] = 'Service temporairement indisponible.'
    redirect_to root_path
  end
end
