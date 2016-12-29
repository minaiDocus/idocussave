# -*- encoding : UTF-8 -*-
class Account::DropboxesController < Account::AccountController
  before_filter :dropbox_authorized?
  before_filter :load_dropbox


  # GET /account/dropboxes/authorize_url
  def authorize_url
    flow = DropboxOAuth2FlowBase.new(Dropbox::APP_KEY, Dropbox::APP_SECRET)

    session[:dropbox_basic_state] = SecureRandom.hex(30)

    redirect_to flow._get_authorize_url(callback_account_dropbox_url, session[:dropbox_basic_state])
  end


  # GET /account/dropboxes/callback
  def callback
    if params[:state].present? && params[:state] == session[:dropbox_basic_state]
      if params[:error] == 'access_denied'
        flash[:notice] = "Vous avez refusé l'accès à votre compte Dropbox."
      else
        begin
          flow = DropboxOAuth2FlowBase.new(Dropbox::APP_KEY, Dropbox::APP_SECRET)

          logger.info(session[:dropbox_basic_state].inspect)

          access_token, user_id = flow._finish(params[:code], callback_account_dropbox_url)

          DropboxBasic.disable_access_token(@dropbox.access_token) if @dropbox.is_configured?

          @dropbox.update(
            access_token:      access_token,
            dropbox_id:        user_id,
            delta_cursor:      nil,
            delta_path_prefix: nil,
            changed_at:        Time.now
          )

          flash[:success] = 'Votre compte Dropbox a été configuré avec succès.'
        rescue DropboxAuthError
          flash[:error] = 'Impossible de configurer votre compte Dropbox.'
        end
      end
    else
      flash[:error] = 'La requête est invalide ou a expiré.'
    end

    session[:dropbox_basic_state] = nil

    redirect_to account_profile_path(panel: 'efs_management')
  end

  private

  def dropbox_authorized?
    unless @user.external_file_storage.try(:is_dropbox_basic_authorized?)
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Dropbox."
      redirect_to account_profile_path
    end
  end


  def load_dropbox
    @dropbox = @user.external_file_storage.try(:dropbox_basic)

    if @dropbox.nil?
      @dropbox = DropboxBasic.new

      @user.find_or_create_external_file_storage.dropbox_basic = @dropbox

      @dropbox.save
    end
  end
end
