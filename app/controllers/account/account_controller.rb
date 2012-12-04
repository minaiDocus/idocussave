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

  def verify_write_access
    unless @user.is_editable?
      flash[:error] = "Vous ne disposez pas des droits nécessaires pour effectuer cette action."
      redirect_to account_profile_path
    end
    true
  end

  def verify_management_access
    unless current_user.is_prescriber || current_user.is_admin
      raise ActionController::RoutingError.new('Not Found')
    end
  end

public
  
  def index
  end
  
end
