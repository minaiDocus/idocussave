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
    results = fiduceo_client.bank_accounts
    if fiduceo_client.response.code == 200 && results[1].any?
      @bank_accounts = results[1].map do |bank_account|
        retriever = FiduceoRetriever.where(fiduceo_id: bank_account.retriever_id).first
        name = [retriever.try(:name), bank_account.name].compact.join(' - ')
        [name, bank_account.id]
      end
      ids = results[1].map(&:id)
      @bank_account_id = params[:bank_account_id] if ids.include? params[:bank_account_id]
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
