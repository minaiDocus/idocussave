class Api::Mobile::RemoteAuthenticationController < ApplicationController
  respond_to :json
  
  def ping
    render :json => {:success=>true, :message=>"Ping success!"}, status: 200
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