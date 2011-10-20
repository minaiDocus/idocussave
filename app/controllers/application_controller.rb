class ApplicationController < ActionController::Base
  protect_from_forgery

  layout :layout_by_resource
  helper_method :format_price
  #around_filter :catch_404 if %w(staging production).include?(Rails.env)

  #before_filter :redirect_to_https

  def layout_by_resource
    if devise_controller? && resource_name == :super_user
      "super_users"
    else
      "devise"
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :user, User
       if session[:order].present?
         address_choice_tunnel_order_url
       else
         account_documents_url
       end
    else
       super
    end
  end

private

  #FIXME No dry see in order_mail NOT DRY
  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",").gsub(/,00/, "")
  end

protected
  
  def redirect_to_https
    if Rails.env.production? && request.env["HTTP_X_FORWARDED_PROTO"] != "https"
      url = request.url.gsub("http", "https")
      redirect_to(url)
    end
  end
  
  def catch_404
    begin
      yield
    rescue ActionController::UnknownAction, ActionController::RoutingError, BSON::InvalidObjectID, BSON::InvalidObjectId
      render "/404", :status => 404
    rescue Mongoid::Errors::DocumentNotFound => e
      #@klass = t e.klass.to_s.downcase
      render "/404", :status => 404
    rescue
      raise
    end
  end
end
