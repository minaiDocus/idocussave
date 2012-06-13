class Account::AccountController < ApplicationController
  before_filter :authenticate_user!
  around_filter :catch_error if %w(staging production).include?(Rails.env)
  
  layout "inner"
  
protected
  
  def catch_error
    begin
      yield
    rescue ActionController::RoutingError
      redirect_to root_url
    rescue  ActionController::UnknownController,
                ActionController::UnknownAction,
                BSON::InvalidObjectId,
                Mongoid::Errors::DocumentNotFound
      @page_types = PageType.by_position rescue []
      @page_in_footer = Page.in_footer.visible.by_position rescue []
      render :template => "404.html.haml", :status => 404, :layout => "inner"
    rescue => e
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      @page_types = PageType.by_position rescue []
      @page_in_footer = Page.in_footer.visible.by_position rescue []
      render :template => "500.html.haml", :status => 500, :layout => "inner"
    end
  end
  
public
  
  def index
  end
  
end
