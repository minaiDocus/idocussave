# frozen_string_literal: true

class Admin::RetrieversController < Admin::AdminController
  def index
    @retrievers = Retriever.search(search_terms(params[:retriever_contains])).order(sort_column => sort_direction).includes(:user, :journal)
    @retrievers_count = @retrievers.count
    @retrievers = @retrievers.page(params[:page]).per(params[:per_page])
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

  def params_fetcher_valid?
    %i[user_code account_ids min_date max_date].each_with_object(params[:budgea_fetcher_contains]) do |key, obj|
      return false unless obj[key].present?
    end
    true
  end
end
