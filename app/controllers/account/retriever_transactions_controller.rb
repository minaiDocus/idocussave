# -*- encoding : UTF-8 -*-
class Account::RetrieverTransactionsController < Account::FiduceoController
  layout 'layouts/account/retrievers'

  def index
    @transactions = search(transaction_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
    @is_filter_empty = transaction_contains.empty?
  end

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

  def transaction_contains
    @contains ||= {}
    if params[:transaction_contains] && @contains.blank?
      @contains = params[:transaction_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :transaction_contains

  def search(contains)
    transactions = @user.fiduceo_transactions.includes(:retriever)
    transactions = transactions.where(custom_service_name: /#{Regexp.quote(contains[:custom_service_name])}/i) if contains[:custom_service_name]
    transactions = transactions.where(type:                Regexp.quote(contains[:type]))                      if contains[:type]
    transactions = transactions.where(status:              Regexp.quote(contains[:status]).upcase)             if contains[:status]
    transactions = transactions.where(created_at:          contains[:created_at])                              if contains[:created_at]
    transactions
  end
end
