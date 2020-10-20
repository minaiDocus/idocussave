# frozen_string_literal: true

class Account::RetrievedBankingOperationsController < Account::RetrieverController
  before_action :verif_account

  def index
    operations
    @is_filter_empty = search_terms(params[:banking_operation_contains]).blank?
    @waiting_operations_count = waiting_operations.count
  end

  def force_processing
    # NOTE using update_all directly does not work because of the join with bank_account
    ids = waiting_operations.pluck(:id)
    count = Operation.where(id: ids).update_all(forced_processing_at: Time.now, forced_processing_by_user_id: current_user.id)
    flash[:success] = if count < 2
                        "#{count} opération sera immédiatement pré-affecté."
                      else
                        "#{count} opérations seront immédiatement pré-affectés."
                      end
    redirect_to account_retrieved_banking_operations_path(banking_operation_contains: params[:banking_operation_contains])
  end

  def unlock_operations
    operations(false)
    if operations(false).present? && params[:banking_operation_contains].present?
      count = operations(false).locked.not_deleted.waiting_processing.where('is_coming = ? AND processed_at IS NULL', false).update_all(is_locked: false)
      if count > 0
        flash[:success] = "#{count} opération(s) débloquée(s) avec succès."
      else
        flash[:error] = 'Aucune opération a été débloquée.'
      end
    end

    redirect_to account_retrieved_banking_operations_path(banking_operation_contains: params[:banking_operation_contains])
  end

  private

  def operations(with_page = true)
    return @operations unless @operations.nil?


    bank_account_ids = @account.bank_accounts.used.map(&:id)

    operations = @account.operations.where(
      Operation.arel_table[:bank_account_id].in(bank_account_ids).or(
        Operation.arel_table[:processed_at].not_eq(nil)
      )
    )
    @operations = Operation.search_for_collection(operations,
                                                  search_terms(params[:banking_operation_contains]))
                                                  .order("#{sort_column} #{sort_direction}")
                                                  .includes(:bank_account)
    if with_page
      @operations = @operations.page(params[:page]).per(params[:per_page])
    end
  end

  def sort_column
    if params[:sort].in? ['date', 'bank_accounts.bank_name', 'bank_accounts.number', 'category', 'label', 'amount']
      params[:sort]
    else
      'date'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction

  def waiting_operations
    bank_account_ids = @account.bank_accounts.used.map(&:id)
    operations = @account.operations.not_processed.not_locked.recently_added.waiting_processing
    operations = operations.where(bank_account_id: bank_account_ids)
    Operation.search_for_collection(operations, search_terms(params[:banking_operation_contains])).includes(:bank_account)
  end

  def verif_account
    if @account.nil?
      redirect_to account_retrievers_path
    end
  end
end
