# -*- encoding : UTF-8 -*-
class Account::RetrieverTransactionsController < Account::FiduceoController
  # GET /account/retriever_transactions
  def index
    @transactions = FiduceoTransaction.search_for_collection_with_options(@user.fiduceo_transactions.includes(:retriever), search_terms(params[:transaction_contains]))
                                                          .includes(:retriever)
                                                          .order(sort_column => sort_direction )

    @transactions_count = @transactions.count

    @transactions = @transactions.page(params[:page]).per(params[:per_page])

    @is_filter_empty = params[:transaction_contains] && params[:transaction_contains].empty?
  end


  # GET /account/retriever_transactions/:id
  def show
    @transaction = @user.fiduceo_transactions.find params[:id]
  end


  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column


  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
