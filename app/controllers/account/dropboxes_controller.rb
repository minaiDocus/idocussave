# frozen_string_literal: true

class Account::DropboxesController < Account::AccountController
  before_action :verify_authorization
  before_action :load_dropbox
  before_action :load_authenticator

  def authorize_url
    redirect_to @authenticator.authorize_url(redirect_uri: callback_account_dropbox_url)
  end

  def callback
    if params[:error] == 'access_denied'
      flash[:error] = "Vous avez refusé l'accès à votre compte Dropbox."
    else
      begin
        auth_bearer = @authenticator.get_token params[:code], redirect_uri: callback_account_dropbox_url
        begin
          if @dropbox.is_configured?
            DropboxApi::Client.new(@dropbox.access_token).revoke_token
          end
        rescue DropboxApi::Errors::HttpError => e
          raise unless e.message.match /HTTP 401/
        end

        @dropbox.update(
          access_token: auth_bearer.token,
          dropbox_id: auth_bearer.params['uid'],
          delta_cursor: nil,
          delta_path_prefix: nil,
          changed_at: Time.now
        )

        flash[:success] = 'Votre compte Dropbox a été configuré avec succès.'
      rescue StandardError => e
        if e.class.name == 'OAuth2::Error'
          flash[:error] = "Impossible de configurer votre compte Dropbox. L'autorisation a peut être expiré."
        else
          flash[:error] = e.to_s
        end
      end
    end

    redirect_to account_profile_path(panel: 'efs_management')
  end

  private

  def verify_authorization
    unless @user.find_or_create_external_file_storage.is_dropbox_basic_authorized?
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Dropbox."
      redirect_to account_profile_path
    end
  end

  def load_authenticator
    @authenticator = DropboxApi::Authenticator.new(Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:key], Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:secret])
  end

  def load_dropbox
    @dropbox = @user.find_or_create_external_file_storage.dropbox_basic
  end
end
