# frozen_string_literal: true

class Account::BoxesController < Account::AccountController
  before_action :verify_authorization
  before_action :load_box

  def authorize_url
    @box.reset_session
    redirect_to @box.get_authorize_url
  end

  def callback
    if params[:error] == 'access_denied'
      flash[:error] = "Vous avez refusé l'accès à votre compte Box."
    else
      @box.get_access_token(params[:code])
      flash[:success] = 'Votre compte Box a été configurée avec succès.'
    end
    redirect_to account_profile_path(panel: 'efs_management')
  end

  private

  def verify_authorization
    unless @user.find_or_create_external_file_storage.is_box_authorized?
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Box."
      redirect_to account_profile_path(panel: 'efs_management')
    end
  end

  def load_box
    @box = @user.find_or_create_external_file_storage.box
  end
end
