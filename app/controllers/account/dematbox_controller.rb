# -*- encoding : UTF-8 -*-
class Account::DematboxController < Account::AccountController
  before_filter :load_dematbox

  def create
    @dematbox.set_new_number
    @dematbox.async_subscribe(params[:pairing_code])
    flash[:notice] = 'Configuration en cours...'
    redirect_to account_profile_path(panel: 'dematbox')
  end

private

  def load_dematbox
    @dematbox = current_user.dematbox || Dematbox.create(user_id: current_user.id)
  end
end
