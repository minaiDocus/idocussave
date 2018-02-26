class Api::Mobile::RemoteAuthenticationController < ApplicationController
  skip_before_action :load_user_and_role
  skip_before_action :verify_suspension
  skip_before_action :verify_if_active
  skip_before_action :load_organization

  respond_to :json

  def ping
    version = params[:version] # app version
    platform = params[:platform] # android or ios
    code = 200 # neutral code
    message = "Ping success"

    #(code 500 for automatically logout app mobile)
      # code = 500
      # message = "Vous n'aves pas l'authorisation necessaire pour acceder au service iDocus, vous allez être déconnecté dans quelques secondes"
    #(code 500 for automatically logout app mobile)

    render :json => {:success=>true, :message=>message, :code=>code}, status: 200
  end

  def request_connexion
    ensure_params_exist
    resource = User.find_for_database_authentication(:email=>params[:user_login][:login])
    return invalid_login_attempt unless resource

    if resource.valid_password?(params[:user_login][:password])
      sign_in("user", resource)
      resource.update_authentication_token unless resource.authentication_token
      render :json => {:success=>true, :user=>resource}, status: 200
      return
    end
    invalid_login_attempt
  end

  # def destroy
  #   current_user.reset_authentication_token
  #   render :json=> {:success=>true}, status: 200
  # end

  protected

  def ensure_params_exist
    return unless params[:user_login].blank?
    render :json=>{:error=>true, :message=>"Paramètre non valide"}, :status=>422
  end

  def invalid_login_attempt
    warden.custom_failure!
    render :json=> {:error=>true, :message=>"Login / Mot de passe incorrect"}, :status=>412
  end
end
