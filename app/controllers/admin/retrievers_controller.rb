# -*- encoding : UTF-8 -*-
class Admin::RetrieversController < Admin::AdminController
  def index
    @retrievers = Retriever.search(search_terms(params[:retriever_contains])).order(sort_column => sort_direction).includes(:user, :journal)
    @retrievers_count = @retrievers.count
    @retrievers = @retrievers.page(params[:page]).per(params[:per_page])
  end

  def fetcher
    if params[:post_action_budgea_fetcher]
      if params_fetcher_valid?
        @message = BudgeaTransactionFetcher.new(
                                                  User.get_by_code(params[:budgea_fetcher_contains][:user_code]),
                                                  params[:budgea_fetcher_contains][:account_ids].split(',').collect {|id| id.delete(' ')},
                                                  params[:budgea_fetcher_contains][:min_date],
                                                  params[:budgea_fetcher_contains][:max_date],
                                                ).execute
      else
        @message = "Paramètre manquant!!"
      end
    end
  end

  def run
    retrievers = Retriever.search(search_terms(params[:retriever_contains]))
    count = retrievers.count
    retrievers.each(&:run)
    flash[:notice] = "#{count} récupération(s) en cours."
    redirect_to admin_retrievers_path(params.permit.except(:authenticity_token))
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
     [:user_code, :account_ids, :min_date, :max_date].each_with_object(params[:budgea_fetcher_contains]) do |key, obj|
      unless obj[key].present?
        return false
      end
    end
    return true
  end

end
