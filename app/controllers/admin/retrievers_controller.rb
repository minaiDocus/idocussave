# -*- encoding : UTF-8 -*-
class Admin::RetrieversController < Admin::AdminController
  def index
    @retrievers = FiduceoRetriever.search(search_terms(params[:retriever_contains])).order(sort_column => sort_direction).includes(:user, :journal)
    @retrievers_count = @retrievers.count
    @retrievers = @retrievers.page(params[:page]).per(params[:per_page])
  end

  def run
    retrievers = search(retriever_contains)
    count = retrievers.count
    retrievers.each(&:run)
    flash[:notice] = "#{count} récupération(s) en cours."
    redirect_to admin_retrievers_path(params.except(:authenticity_token))
  end

private

  def load_retriever
    @retriever = Retriever.find params[:id]
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
