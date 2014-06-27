# -*- encoding : UTF-8 -*-
class Account::RetrievedBankingOperationsController < Account::FiduceoController
  layout 'layouts/account/retrievers'

  def index
    @operations = search(banking_operation_contains).
      order([sort_column,sort_direction]).
      page(params[:page]).
      per(params[:per_page])
    @is_filter_empty = banking_operation_contains.blank?
  end

private

  def sort_column
    params[:sort] || 'date'
  end

  def sort_direction
    params[:direction] || 'desc'
  end

  def banking_operation_contains
    @contains ||= {}
    if params[:banking_operation_contains] && @contains.blank?
      @contains = params[:banking_operation_contains].delete_if do |_,value|
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
  helper_method :banking_operation_contains

  def search(contains)
    operations = @user.operations.fiduceo
    operations = operations.where(label: /#{Regexp.quote(contains[:label])}/i) unless contains[:label].blank?
    begin
      operations = operations.where(date: contains[:date]) unless contains[:date].blank?
    rescue Mongoid::Errors::InvalidTime
      contains[:date] = nil
    end
    operations
  end
end
