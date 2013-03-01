# -*- encoding : UTF-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :format_price, :format_price_00

  before_filter :redirect_to_https if Rails.env.production?
  before_filter :load_gray_label
  around_filter :catch_error if %w(staging production test).include?(Rails.env)
  around_filter :log_visit if %w(staging production test).include?(Rails.env)

  def after_sign_in_path_for(resource_or_scope)
    if session[:targeted_path]
      path = session[:targeted_path]
      session[:targeted_path] = nil
      path
    else
      case resource_or_scope
      when :user, User
        account_documents_url
      when :admin
        admin_root_url
      else
        super
      end
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    @gray_label ? "/gr/sessions/#{@gray_label.slug}/destroy" : SITE_DEFAULT_URL
  end

  def login_user!
    unless current_user and request.path.match(/^\/users.*/)
      session[:targeted_path] = request.path
    end
    authenticate_user!
  end

  def load_user(name=:@user)
    value = nil
    if current_user
      if (params[:code].present? || session[:acts_as].present?) && current_user.try(:is_admin)
        value = User.find_by_code(params[:code] || session[:acts_as]) || current_user
        if value == current_user
          session[:acts_as] = nil
        else
          session[:acts_as] = value.code
        end
      else
        value = current_user
      end
    end
    instance_variable_set name, value
  end

private

  def format_price_00 price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end

  def format_price price_in_cents
    format_price_00(price_in_cents).gsub(/,00/, "")
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
    rescue ActionController::UnknownController,
           AbstractController::ActionNotFound,
           BSON::InvalidObjectId,
           Mongoid::Errors::DocumentNotFound
      render "/404.html.haml", :status => 404, :layout => "pages"
    rescue => e
      user_info = "[visiteur]"
      if current_user
        user_info = ["#{current_user.try(:code)} :",current_user.try(:name),"<#{current_user.email}>"].reject{ |i| i.nil? }.join(' ')
      end
      ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => { :user_info => "#{user_info}" }).deliver
      render "/500.html.haml", :status => 500, :layout => "pages"
    end
  end

  def authenticate_admin_user!
    authenticate_user!
    unless current_user && current_user.is_admin
      flash[:error] = "Vous n'avez pas accès à cette page!"
      redirect_to root_path
    end
  end
  
  def log_visit
    unless request.path.match('(system|assets|num)') || !params[:action].in?(%w(index show))
      unless current_user && current_user.is_admin
        visit            = ::Log::Visit.new
        visit.path       = request.path
        visit.user       = current_user.try(:id)
        visit.ip_address = request.remote_ip 
        visit.save
      end
    end
    yield
  end

  def load_gray_label
    unless request.fullpath.match('/admin')
      if current_user
        @gray_label = (current_user.try(:prescriber) || current_user).try(:gray_label)
        if @gray_label && @gray_label.is_active
          session[:gray_label_slug] = @gray_label.try(:slug)
        else
          @gray_label = nil
        end
        @gray_label
      else
        @gray_label = GrayLabel.find_by_slug session[:gray_label_slug]
        @gray_label = nil unless @gray_label && @gray_label.is_active
      end
    end
  end
end
