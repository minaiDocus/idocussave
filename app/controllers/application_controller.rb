class ApplicationController < ActionController::Base
  protect_from_forgery
  
  layout :layout_by_resource
  helper_method :format_price
  
  before_filter :redirect_to_https if Rails.env.production?
  around_filter :catch_error if %w(staging production).include?(Rails.env)
  
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
  
  def format_price_00 price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end
  
private
  
  #FIXME No dry see in order_mail NOT DRY
  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",").gsub(/,00/, "")
  end
  
protected
  
  def redirect_to_https
    if request.env["HTTP_X_FORWARDED_PROTO"] != "https"
      url = request.url.gsub("http", "https")
      redirect_to(url)
    end
  end
  
  def catch_error
    begin
      yield
    rescue  ActionController::UnknownController,
                ActionController::UnknownAction,
                BSON::InvalidObjectId,
                Mongoid::Errors::DocumentNotFound
      @page_types = PageType.by_position rescue []
      @page_in_footer = Page.in_footer.visible.by_position rescue []
      render :template => "404.html.haml", :status => 404, :layout => "pages"
    rescue => e
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      @page_types = PageType.by_position rescue []
      @page_in_footer = Page.in_footer.visible.by_position rescue []
      render :template => "500.html.haml", :status => 500, :layout => "pages"
    end
  end
  
end
