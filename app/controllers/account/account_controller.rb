# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  before_filter :load_user_and_role
  around_filter :catch_error if %w(staging sandbox production test).include?(Rails.env)
  
  layout "inner"
  
protected
  
  def catch_error
    begin
      yield
    rescue ActionController::UnknownController,
           AbstractController::ActionNotFound,
           BSON::InvalidObjectId,
           Mongoid::Errors::DocumentNotFound,
           ActionController::RoutingError
      render "/404.html.haml", :status => 404, :layout => "inner"
    rescue Fiduceo::Errors::ServiceUnavailable => e
      Airbrake.notify(e, airbrake_request_data)
      render "/503.html.haml", :status => 503, :layout => "inner"
    rescue => e
      Airbrake.notify(e, airbrake_request_data)
      render "/500.html.haml", :status => 500, :layout => "inner"
    end
  end

  def load_user_and_role(name=:@user)
    instance = load_user(name)
    instance.extend_organization_role if instance
  end
  
  def load_fiduceo_user_id
    @fiduceo_user_id = @user.fiduceo_id || FiduceoUser.new(@user).create
  end

  def load_bank_accounts
    @bank_accounts = @user.bank_accounts.asc([:bank_name, :number]).map do |bank_account|
      name = [bank_account.retriever.name, bank_account.name, bank_account.number].join(' - ')
      [name, bank_account.fiduceo_id]
    end
    if @bank_accounts.any?
      ids = @bank_accounts.map { |e| e[1] }
      @bank_account_id = params[:bank_account_id] if params[:bank_account_id].in? ids
      @bank_account_id = ids.first unless @bank_account_id
    else
      redirect_to account_documents_path, flash: { error: "Vous n'avez pas de compte bancaire configuré." }
    end
  end

  def fiduceo_client
    @fiduceo_client ||= Fiduceo::Client.new @user.fiduceo_id, cache: true
  end

  public
  
  def index
  end
  
end
