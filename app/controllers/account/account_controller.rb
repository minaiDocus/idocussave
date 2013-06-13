# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  around_filter :catch_error if %w(staging production test).include?(Rails.env)
  
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

  public
  
  def index
  end
  
end
