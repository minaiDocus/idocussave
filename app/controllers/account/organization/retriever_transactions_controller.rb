# -*- encoding : UTF-8 -*-
class Account::Organization::RetrieverTransactionsController < Account::Organization::FiduceoController
  # GET /account/organizations/:organization_id/customers/:customer_id/retriever_transactions
  def index
    @transactions = FiduceoTransaction.search_for_collection_with_options(@customer.fiduceo_transactions, search_terms(params[:transaction_contains]))
                                                          .includes(:retriever)
                                                          .order(sort_column => sort_direction )

    @transactions_count = @transactions.count

    @transactions = @transactions.page(params[:page]).per(params[:per_page])
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/retriever_transactions/:id
  def show
    @transaction = @customer.fiduceo_transactions.find params[:id]
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
