# frozen_string_literal: true

class Api::Mobile::OperationsController < MobileApiController
  respond_to :json

  include Account::Organization::OperationHelper

  def get_operations
    @customer = User.find params[:user_id]
    @filter = params[:filter] || {}
    if @filter.try(:[], :date).try(:[], :start_date)
      @filter[:date]['>='] = @filter.try(:[], 'date').try(:[], :start_date)
    end
    if @filter.try(:[], :date).try(:[], :end_date)
      @filter[:date]['<='] = @filter.try(:[], 'date').try(:[], :end_date)
    end

    if @customer
      direction = params[:order][:direction] ? 'asc' : 'desc'

      order_by = case params[:order][:order_by]
                 when 'bank_accounts.bank_name'
                   'bank_accounts.bank_name'
                 when 'bank_accounts.number'
                   'bank_accounts.number'
                 when 'category'
                   'category'
                 when 'label'
                   'label'
                 when 'amount'
                   'amount'
                 else
                   'date'
                 end

      bank_account_ids = @customer.bank_accounts.used.map(&:id)
      operations = @customer.operations.retrieved.where(
        Operation.arel_table[:bank_account_id].in(bank_account_ids).or(
          Operation.arel_table[:processed_at].not_eq(nil)
        )
      )
      operations = Operation.search_for_collection(operations, search_terms(@filter)).order("#{order_by} #{direction}").includes(:bank_account).page(params[:page]).per(30)

      waiting_operations_count = waiting_operations.count

      result = operations.map do |operation|
        {
          id: operation.id,
          label: operation.label,
          date: operation.date,
          service: operation.bank_account.try(:bank_name),
          compte: operation.bank_account.try(:number),
          category: operation.category,
          amount: operation.amount,
          pre_assigned: is_operation_pre_assigned(operation),
          unit: operation.currency['symbol'] || '€'
        }
      end

      render json: { operations: result, nb_pages: operations.total_pages, total: operations.total_count, waiting_operations_count: waiting_operations_count }, status: 200
    else
      render json: { operations: [], nb_pages: 0, total: 0, waiting_operations_count: 0 }, status: 200
    end
  end

  def force_pre_assignment
    @customer = User.find params[:user_id]
    if @customer
      # NOTE using update_all directly does not work because of the join with bank_account
      ids = waiting_operations.pluck(:id)
      count = Operation.where(id: ids).update_all(forced_processing_at: Time.now, forced_processing_by_user_id: current_user.id)
    end
    render json: { success: true }, status: 200
  end

  def get_customers_options
    @customers = User.where(id: params[:user_ids])

    options = []
    if @customers
      options = @customers.map do |customer|
        next unless customer.subscription.is_package?('retriever_option')

        {
          user_id: customer.id,
          force_pre_assignment: current_user.collaborator? && !customer.try(:options).try(:operation_processing_forced?)
        }
      end
    end

    render json: { success: true, options: options.compact }, status: 200
  end

  private

  def waiting_operations
    bank_account_ids = @customer.bank_accounts.used.map(&:id)
    operations = @customer.operations.not_processed.not_locked.recently_added.waiting_processing
    operations = operations.where(bank_account_id: bank_account_ids)
    Operation.search_for_collection(operations, search_terms(@filter)).includes(:bank_account)
  end
end
