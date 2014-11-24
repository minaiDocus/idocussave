# -*- encoding : UTF-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :format_price, :format_price_00

  before_filter :redirect_to_https if %w(staging sandbox production).include?(Rails.env)
  before_filter :load_gray_label
  around_filter :catch_error if %w(staging sandbox production test).include?(Rails.env)
  around_filter :log_visit # if %w(staging sandbox production test).include?(Rails.env)

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
    user = nil
    if current_user && current_user.is_admin
      if request.path.match /organizations/
        if params[:collaborator_code].present? || session[:collaborator_code].present?
          user = User.prescribers.where(code: params[:collaborator_code].presence || session[:collaborator_code].presence).first || current_user
          session[:collaborator_code] = user == current_user ? nil : user.code
        end
      elsif params[:user_code].present? || session[:user_code].present?
        user = User.find_by_code(params[:user_code].presence || session[:user_code].presence) || current_user
        session[:user_code] = user == current_user ? nil : user.code
      end
    end
    user ||= current_user
    instance_variable_set name, user
  end

  def present(object, klass=nil)
    klass ||= "#{object.class}Presenter".constantize
    klass.new(object)
  end

private

  def format_price_with_dot price_in_cents
    "%0.2f" % (price_in_cents.round/100.0)
  end

  def format_price_00 price_in_cents
    format_price_with_dot(price_in_cents).gsub(".", ",")
  end

  def format_price price_in_cents
    format_price_00(price_in_cents).gsub(/,00/, "")
  end

protected

  def redirect_to_https
    if request.env["HTTP_X_FORWARDED_PROTO"] != "https" && !request.path.match(/^\/dematbox\//)
      url = request.url.gsub("http", "https")
      redirect_to(url)
    end
  end

  def catch_error
    begin
      yield
    rescue ActionController::UnknownController,
           ActionController::RoutingError,
           AbstractController::ActionNotFound,
           BSON::InvalidObjectId,
           Mongoid::Errors::DocumentNotFound
      render '/404', status: 404
    rescue => e
      Airbrake.notify(e, airbrake_request_data)
      render '/500', status: 500
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
    unless request.path.match('(dematbox|system|assets|num)') || !params[:action].in?(%w(index show)) || (controller_name == 'retrievers' && params[:part].present?)
      unless current_user && current_user.is_admin
        event = Event.new
        event.action      = 'visit'
        event.target_name = request.path
        event.target_type = 'page'
        event.user        = current_user
        event.path        = request.path
        event.ip_address  = request.remote_ip
        event.save
      end
    end
    yield
  end

  def load_gray_label
    unless request.fullpath.match('/admin')
      if current_user
        @gray_label = current_user.organization.try(:gray_label)
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

  def verify_suspension
    if controller_name == 'suspended'
      redirect_to account_root_path unless @user.try(:organization).try(:is_suspended)
    elsif @user.try(:organization).try(:is_suspended)
      unless ((controller_name == 'profiles' && action_name == 'show') || controller_name == 'payments') && @user.organization.leader == @user
        redirect_to account_suspended_path
      end
    end
  end
end
