# -*- encoding : UTF-8 -*-
class Account::AccountController < ApplicationController
  before_filter :login_user!
  around_filter :catch_error if %w(staging production).include?(Rails.env)
  
  layout "inner"
  
protected
  
  def catch_error
    begin
      yield
    rescue  ActionController::UnknownController,
                ActionController::UnknownAction,
                BSON::InvalidObjectId,
                Mongoid::Errors::DocumentNotFound
      render :template => "404.html.haml", :status => 404, :layout => "inner"
    rescue => e
      user_info = ["#{current_user.try(:code)} :",current_user.try(:name),"<#{current_user.email}>"].reject{ |i| i.nil? }.join(' ')
      ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => { :user_info => "#{user_info}" }).deliver
      render :template => "500.html.haml", :status => 500, :layout => "inner"
    end
  end
  
public
  
  def index
  end
  
end
