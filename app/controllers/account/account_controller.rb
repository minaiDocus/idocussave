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
           Mongoid::Errors::DocumentNotFound
      render "/404", :status => 404, :layout => "inner"
    rescue => e
      user_info = ["#{current_user.try(:code)} :",current_user.try(:name),"<#{current_user.email}>"].reject{ |i| i.nil? }.join(' ')
      ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => { :user_info => "#{user_info}" }).deliver
      render "/500", :status => 500, :layout => "inner"
    end
  end
  
public
  
  def index
  end
  
end
