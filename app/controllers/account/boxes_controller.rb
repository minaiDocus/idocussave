# -*- encoding : UTF-8 -*-
class Account::BoxesController < Account::AccountController
  before_filter :box_authorized?
  before_filter :load_box

private

  def box_authorized?
    unless @user.external_file_storage.try('is_box_authorized?')
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Box."
      redirect_to account_profile_path(panel: 'efs_management')
    end
  end

  def load_box
    @box = @user.external_file_storage.try('box')
    unless @box
      external_file_storage = @user.find_or_create_external_file_storage
      @box = Box.create(external_file_storage_id: external_file_storage.id)
    end
  end

public

  def authorize_url
    @box.reset_session
    redirect_to @box.get_authorize_url
  end

  def callback
    @box.get_access_token(params[:code])
    flash[:notice] = 'Votre compte Box a été configurée avec succès.'
    redirect_to account_profile_path(panel: 'efs_management')
  end
end
