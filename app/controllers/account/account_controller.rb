class Account::AccountController < ApplicationController
  before_filter :authenticate_user!
  #around_filter :catch_404

  skip_before_filter :authenticate_super_user!
  
  layout "inner"

protected

  def catch_404
    begin
      yield
    rescue ActionController::UnknownAction, ActionController::RoutingError, BSON::InvalidObjectID, BSON::InvalidObjectId
      render "/account/404", :status => 404
    rescue Mongoid::Errors::DocumentNotFound => e
      #@klass = t e.klass.to_s.downcase
      render "/account/404", :status => 404
    rescue
      raise
    end
  end

public

  def index

  end


end
