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
      user_info = "[visiteur]"
      if current_user
        user_info = ["#{current_user.try(:code)} :",current_user.try(:name),"<#{current_user.email}>"].reject{ |i| i.nil? }.join(' ')
      end
      ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => { :user_info => "#{user_info}" }).deliver
      render "/500.html.haml", :status => 500, :layout => "inner"
    end
  end

  def load_user_and_role(name=:@user)
    instance = load_user(name)
    if instance.is_prescriber
      if instance.my_organization
        instance.extend OrganizationManagement::Leader
      elsif instance.organization
        instance.extend OrganizationManagement::Collaborator
      end
    end
  end

  public
  
  def index
  end
  
end
