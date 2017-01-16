# -*- encoding : UTF-8 -*-
class Admin::NewProviderRequestsController < Admin::AdminController
  before_filter :load_new_provider_request, except: :index

  def index
    @new_provider_requests = search(new_provider_request_contains).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def edit
  end

  def start_process
    @new_provider_request.start_process
    RequestNewProvider.new(@new_provider_request.id).delay.execute
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_new_provider_requests_path
  end

  def reject
    if params[:new_provider_request] && params[:new_provider_request][:message].present?
      @new_provider_request.update_attribute(:message, params[:new_provider_request][:message])
    end
    @new_provider_request.reject
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_new_provider_requests_path
  end

  def accept
    @new_provider_request.accept
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_new_provider_requests_path
  end

private

  def load_new_provider_request
    @new_provider_request = NewProviderRequest.find params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def new_provider_request_contains
    @contains ||= {}
    if params[:new_provider_request_contains] && @contains.blank?
      @contains = params[:new_provider_request_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :new_provider_request_contains

  def search(contains)
    user_ids = []
    if params[:user_contains] && params[:user_contains][:code].present?
      user_ids = User.where(code: /#{Regexp.quote(params[:user_contains][:code])}/i).distinct(:_id)
    end
    new_provider_requests = NewProviderRequest.all
    new_provider_requests = new_provider_requests.where(created_at:    contains[:created_at])                unless contains[:created_at].blank?
    new_provider_requests = new_provider_requests.where(updated_at:    contains[:updated_at])                unless contains[:updated_at].blank?
    new_provider_requests = new_provider_requests.any_in(user_id:      user_ids)                             if user_ids.any?
    new_provider_requests = new_provider_requests.where(state:         contains[:state])                     unless contains[:state].blank?
    new_provider_requests = new_provider_requests.where(name:          /#{Regexp.quote(contains[:name])}/i)  unless contains[:name].blank?
    new_provider_requests = new_provider_requests.where(url:           /#{Regexp.quote(contains[:url])}/i)   unless contains[:url].blank?
    new_provider_requests = new_provider_requests.where(email:         /#{Regexp.quote(contains[:email])}/i) unless contains[:email].blank?
    new_provider_requests = new_provider_requests.where(login:         /#{Regexp.quote(contains[:login])}/i) unless contains[:login].blank?
    new_provider_requests = new_provider_requests.where(notified_at:   contains[:notified_at])               unless contains[:notified_at].blank?
    new_provider_requests = new_provider_requests.where(processing_at: contains[:processing_at])             unless contains[:processing_at].blank?
    if contains[:is_notified]
      if contains[:is_notified].to_i == 1
        new_provider_requests = new_provider_requests.notified
      elsif contains[:is_notified].to_i == 0
        new_provider_requests = new_provider_requests.not_notified
      end
    end
    new_provider_requests
  end
end
