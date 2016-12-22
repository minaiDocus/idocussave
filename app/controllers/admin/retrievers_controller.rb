# -*- encoding : UTF-8 -*-
# FIXME : check if needed
class Admin::RetrieversController < Admin::AdminController
  # GET /admin/retrievers
  def index
    @retrievers = FiduceoRetriever.search(search_terms(params[:retriever_contains])).order(sort_column => sort_direction).includes(:user, :journal)

    @retrievers_count = @retrievers.count

    @retrievers = @retrievers.page(params[:page]).per(params[:per_page])
  end


  # GET /admin/retrievers/:id/edit
  def edit
  end


  # DELETE /admin/retrievers/:id
  def destroy
  end


  # GET /admin/retrievers/:id/edit
  def fetch
    retrievers = search(retriever_contains)
    count = retrievers.count
    FiduceoDocumentFetcher.initiate_transactions(retrievers)
    flash[:notice] = "#{count} récupération(s) en cours."
    redirect_to admin_fiduceo_retrievers_path(params.except(:authenticity_token))
  end

  private

  def load_retriever
    @retriever = FiduceoRetriever.find params[:id]
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
