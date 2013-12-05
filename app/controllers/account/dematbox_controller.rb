# -*- encoding : UTF-8 -*-
class Account::DematboxController < Account::AccountController
  before_filter :verify_access
  before_filter :load_dematbox

  def create
    @dematbox.set_new_number
    @dematbox.async_subscribe(params[:pairing_code])
    flash[:notice] = 'Configuration en cours...'
    redirect_to account_profile_path(panel: 'dematbox')
  end

private

  def verify_access
    unless @user.is_dematbox_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_profile_path
    end
  end

  def load_dematbox
    @dematbox = @user.dematbox || Dematbox.create(user_id: @user.id)
  end
end
