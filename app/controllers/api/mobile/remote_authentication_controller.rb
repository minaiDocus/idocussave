# frozen_string_literal: true

class Api::Mobile::RemoteAuthenticationController < ApplicationController
  respond_to :json

  def ping
    version = params[:version] # app version
    platform = params[:platform] # android or ios
    build_code = params[:build_code] || 0 # build code released

    code = 200 # neutral code
    message = 'Ping success'

    # (code 500 for automatically logout app mobile)
    if build_code.to_i < 6 || build_code.nil?
      code = 500
      message = "Le service iDocus actuel nécessite une version plus récente de l'application; Veuillez mettre à jour votre application iDocus s'il vous plaît. Merci."
    end
    # (code 500 for automatically logout app mobile)

    render json: { success: true, message: message, code: code }, status: 200
  end

  def request_connexion
    ensure_params_exist

    user = User.find_by_mail_or_code(params[:user_login][:login])
    return invalid_login_attempt unless user

    resource = User.find_for_database_authentication(email: user.email)
    return invalid_login_attempt unless resource

    if resource.valid_password?(params[:user_login][:password])
      sign_in('user', resource)
      resource.get_authentication_token

      user = resource
      resource = Collaborator.new resource if resource.collaborator?

      user.code = resource.try(:code) || '-'
      user.organization_id = resource.try(:organization).try(:id) || '0'

      render json: { success: true, user: user }, status: 200
      return
    end

    invalid_login_attempt
  end

  def get_user_parameters
    user = User.find params[:user_id]

    render json: { success: true, parameters: { show_preseizures: user.try(:pre_assignement_displayed?) || false } }, status: 200
  end

  # def destroy
  #   current_user.reset_authentication_token
  #   render json: { success: true }, status: 200
  # end

  protected

  def ensure_params_exist
    return unless params[:user_login].blank?

    render json: { error: true, message: 'Paramètre non valide' }, status: 422
  end

  def invalid_login_attempt
    warden.custom_failure!
    render json: { error: true, message: 'Login / Mot de passe incorrect' }, status: 412
  end
end
