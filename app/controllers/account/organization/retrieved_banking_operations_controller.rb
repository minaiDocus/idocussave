# -*- encoding : UTF-8 -*-
class Account::Organization::RetrievedBankingOperationsController < Account::Organization::RetrieverController
  def index
    @operations = operations
    @waiting_operations_count = waiting_operations.count
  end

  def force_processing
    # NOTE using update_all directly does not work because of the join with bank_account
    ids = waiting_operations.pluck(:id)
    count = Operation.where(id: ids).update_all(forced_processing_at: Time.now, forced_processing_by_user_id: current_user.id)
    if count < 2
      flash[:success] = "#{count} opération sera immédiatement pré-affecté."
    else
      flash[:success] = "#{count} opérations seront immédiatement pré-affectés."
    end
    redirect_to account_organization_customer_retrieved_banking_operations_path(@organization, @customer, banking_operation_contains: params[:banking_operation_contains])
  end

  def unlock_operations
    if operations.present? && params[:banking_operation_contains].present?
      count = operations.locked.not_deleted.waiting_processing.where("is_coming = ? AND processed_at IS NULL", false).update_all(:is_locked => false)
      if count > 0
        flash[:success] = "#{count} débloquée(s) avec succès."
      else
        flash[:error] = "Aucune opération a été débloquée."
      end
    end
    redirect_to account_organization_customer_retrieved_banking_operations_path(@organization, @customer, banking_operation_contains: params[:banking_operation_contains])    
  end 

private

  def sort_column
    if params[:sort].in? ['date', 'bank_accounts.bank_name', 'bank_accounts.number', 'category', 'label', 'amount']
      params[:sort]
    else
      'date'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w(asc desc)
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction

  def operations
    bank_account_ids = @customer.bank_accounts.used.map(&:id)
    operations = @customer.operations.retrieved.where(
      Operation.arel_table[:bank_account_id].in(bank_account_ids).or(
        Operation.arel_table[:processed_at].not_eq(nil)
      )
    )
    Operation.search_for_collection(operations, search_terms(params[:banking_operation_contains])).order("#{sort_column} #{sort_direction}").includes(:bank_account).page(params[:page]).per(params[:per_page])
  end

  def waiting_operations
    bank_account_ids = @customer.bank_accounts.used.map(&:id)
    operations = @customer.operations.not_processed.not_locked.recently_added.waiting_processing
    operations = operations.where(bank_account_id: bank_account_ids)
    Operation.search_for_collection(operations, search_terms(params[:banking_operation_contains]))
  end
end
