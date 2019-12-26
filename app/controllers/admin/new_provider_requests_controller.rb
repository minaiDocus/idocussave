# frozen_string_literal: true

class Admin::NewProviderRequestsController < Admin::AdminController
  before_action :load_new_provider_request, except: :index

  def index
    @new_provider_requests = NewProviderRequest.search(search_terms(params[:new_provider_request_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @new_provider_requests_count = NewProviderRequest.count
  end

  def show; end

  def edit; end

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
end
