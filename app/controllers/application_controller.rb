# -*- encoding : UTF-8 -*-
# FIXME : whole check
class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :format_price, :format_price_00

  before_filter :redirect_to_https if %w(staging sandbox production).include?(Rails.env)
  around_filter :catch_error if %w(staging sandbox production test).include?(Rails.env)
  around_filter :log_visit
  before_filter :load_current_time


  def after_sign_in_path_for(resource_or_scope)
    if session[:targeted_path]
      path = session[:targeted_path]
      session[:targeted_path] = nil
      path
    else
      case resource_or_scope
      when :user, User
        root_url
      when :admin
        admin_root_url
      else
        super
      end
    end
  end


  def after_sign_out_path_for(_resource_or_scope)
    "https://www.idocus.com"
  end


  def login_user!
    unless current_user && request.path.match(/\A\/users.*/)
      session[:targeted_path] = request.path
    end
    authenticate_user!
  end


  def load_user(name = :@user)
    user = nil
    if current_user && current_user.is_admin
      if request.path =~ /organizations/
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


  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    klass.new(object)
  end

  private

  def search_terms(search_terms_from_parameters)
    @contains ||= {}
    if search_terms_from_parameters && @contains.blank?
      @contains = search_terms_from_parameters.delete_if do |_, value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |_k, v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :search_terms


  def format_price_with_dot(price_in_cents)
    '%0.2f' % (price_in_cents.round / 100.0)
  end


  def format_price_00(price_in_cents)
    format_price_with_dot(price_in_cents).tr('.', ',')
  end


  def format_price(price_in_cents)
    format_price_00(price_in_cents).gsub(/,00/, '')
  end

  protected


  def load_current_time
    @current_time = Time.now

    if params[:year] && params[:month] && params[:day]
      begin
        @current_time = Time.local(params[:year], params[:month], params[:day])
      rescue ArgumentError
        @current_time = Time.now
      end
    end
  end


  def redirect_to_https
    if !request.ssl? && !request.path.match(/(^\/dematbox\/|debit_mandate_notify)/)
      url = request.url.gsub('http', 'https')
      redirect_to(url)
    end
  end


  def catch_error
    begin
      yield
    rescue ActionController::UnknownController,
           ActionController::RoutingError,
           AbstractController::ActionNotFound
      respond_to do |format|
        format.html { render '/404', status: 404, layout: (@user ? 'inner' : 'error') }
        format.json { render json: { status: :not_found, code: 404 } }
      end
    rescue Budgea::Errors::ServiceUnavailable => e
      Airbrake.notify(e, airbrake_request_data)
      respond_to do |format|
        format.html { render '/503', status: 503, layout: 'inner' }
        format.json { render json: { status: :error, code: 503 } }
      end
    rescue => e
      Airbrake.notify(e, airbrake_request_data)
      respond_to do |format|
        format.html { render '/500', status: 500, layout: (@user ? 'inner' : 'error') }
        format.json { render json: { status: :error, code: 500 } }
      end
    end
  rescue ActionController::UnknownFormat
    render status: 400, text: '404'
  end


  def authenticate_admin_user!
    authenticate_user!
    unless current_user && current_user.is_admin
      flash[:error] = "Vous n'avez pas accès à cette page!"
      redirect_to root_path
    end
  end


  def log_visit
    unless request.path.match('(dematbox|system|assets|num|preview)') || !params[:action].in?(%w(index show)) || (controller_name == 'retrievers' && params[:part].present?)
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


  def verify_suspension
    if controller_name == 'suspended'
      redirect_to root_path unless @user.try(:organization).try(:is_suspended) && @user.active?
    elsif @user.try(:organization).try(:is_suspended) && @user.active?
      unless ((controller_name == 'profiles' && action_name == 'show') || controller_name == 'payments') && @user.organization.leader == @user
        redirect_to account_suspended_path
      end
    end
  end
end
