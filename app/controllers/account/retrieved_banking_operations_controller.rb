# -*- encoding : UTF-8 -*-
class Account::RetrievedBankingOperationsController < Account::RetrieverController
  def index
    bank_account_ids = @user.bank_accounts.used.map(&:id)
    operations = @user.operations.retrieved.where(bank_account_id: bank_account_ids)
    @operations = Operation.search_for_collection(operations, search_terms(params[:banking_operation_contains])).order(sort_column => sort_direction).includes(:bank_account)
    @operations_count = @operations.count
    @operations = @operations.page(params[:page]).per(params[:per_page])
    @is_filter_empty = search_terms(params[:banking_operation_contains]).blank?
  end

private

  def sort_column
    params[:sort] || 'date'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
