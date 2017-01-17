# -*- encoding : UTF-8 -*-
class Account::Organization::RetrievedBankingOperationsController < Account::Organization::RetrieverController
  def index
    bank_account_ids = @customer.bank_accounts.used.map(&:id)
    operations = @customer.operations.retrieved.where(bank_account_id: bank_account_ids)
    @operations = Operation.search_for_collection(operations, search_terms(params[:banking_operation_contains])).order(sort_column => sort_direction).includes(:bank_account)
    @operations_count = @operations.count
    @operations = @operations.page(params[:page]).per(params[:per_page])
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
