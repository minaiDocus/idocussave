# -*- encoding : UTF-8 -*-
class Account::DropboxesController < Account::AccountController
  before_filter :dropbox_authorized?
  before_filter :load_dropbox

private

  def dropbox_authorized?
    unless @user.external_file_storage.try("is_dropbox_basic_authorized?")
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Dropbox."
      redirect_to account_profile_path
    end
  end

  def load_dropbox
    @dropbox = @user.external_file_storage.try("dropbox_basic")
    if @dropbox.nil?
      @dropbox = DropboxBasic.new
      @user.find_or_create_external_file_storage.dropbox_basic = @dropbox
      @dropbox.save
    end
  end

public

  def authorize_url
    @dropbox.reset_session
    @dropbox.new_session
    redirect_to @dropbox.get_authorize_url callback_account_dropbox_url
    # render :text => @dropbox.get_authorize_url(callback_account_dropbox_url)
  end

  def callback
    if params[:not_approved] == 'true'
      flash[:notice] = 'Configuration de Dropbox annulée.'
    else
      @dropbox.get_access_token
      flash[:notice] = 'Votre compte Dropbox a été configuré avec succès.'
    end
    redirect_to account_profile_path(panel: 'efs_management')
  end
end
