# frozen_string_literal: true

class Account::DematboxController < Account::AccountController
  before_action :verify_access
  before_action :load_dematbox

  # POST /account/dematboxes
  def create
    @dematbox.subscribe(params[:pairing_code])
    flash[:notice] = "Configuration de iDocus'Box en cours..."
    redirect_to account_profile_path(panel: 'idocus_box')
  end

  # DELETE /account/dematboxes
  def destroy
    @dematbox.unsubscribe
    flash[:notice] = 'Supprimé avec succèss.'
    redirect_to account_profile_path(panel: 'idocus_box')
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
