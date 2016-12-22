# -*- encoding : UTF-8 -*-
class Admin::ProviderWishesController < Admin::AdminController
  before_filter :load_provider_wish, except: :index

  # GET /admin/provider_wishes
  def index
    @provider_wishes = FiduceoProviderWish.search(search_terms(params[:provider_wish_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end


  # GET /admin/provider_wishes/:id
  def show
  end


  # GET /admin/provider_wishes/:id/edit
  def edit
  end


  # GET /admin/provider_wishes/:id/start_process
  def start_process
    @provider_wish.start_process

    flash[:notice] = 'Statut changé avec succès.'

    redirect_to admin_fiduceo_provider_wishes_path
  end


  # GET /admin/provider_wishes/:id/reject
  def reject
    if params[:fiduceo_provider_wish] && params[:fiduceo_provider_wish][:message].present?
      @provider_wish.update_attribute(:message, params[:fiduceo_provider_wish][:message])
    end

    @provider_wish.reject

    flash[:notice] = 'Statut changé avec succès.'

    redirect_to admin_fiduceo_provider_wishes_path
  end


  # GET /admin/provider_wishes/:id/accept
  def accept
    @provider_wish.accept

    flash[:notice] = 'Statut changé avec succès.'

    redirect_to admin_fiduceo_provider_wishes_path
  end

  private

  def load_provider_wish
    @provider_wish = FiduceoProviderWish.find params[:id]
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
