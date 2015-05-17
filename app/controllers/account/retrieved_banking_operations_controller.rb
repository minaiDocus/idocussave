# -*- encoding : UTF-8 -*-
class Account::RetrievedBankingOperationsController < Account::FiduceoController
  def index
    @operations = search(banking_operation_contains).
      order_by(sort_column => sort_direction).
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
    operations = operations.where(category: /#{Regexp.quote(contains[:category])}/i) unless contains[:category].blank?
    operations = operations.where(label:    /#{Regexp.quote(contains[:label])}/i)    unless contains[:label].blank?
    begin
      operations = operations.where(date: contains[:date]) unless contains[:date].blank?
    rescue Mongoid::Errors::InvalidTime
      contains[:date] = nil
    end
    if contains[:bank_account].present? && (contains[:bank_account][:bank_name].present? || contains[:bank_account][:number].present?)
      bank_name = contains[:bank_account][:bank_name] rescue nil
      number    = contains[:bank_account][:number]    rescue nil
      bank_accounts = @user.bank_accounts
      bank_accounts = bank_accounts.where(bank_name: /#{Regexp.quote(bank_name)}/i) if bank_name.present?
      bank_accounts = bank_accounts.where(number:    /#{Regexp.quote(number)}/i)    if number.present?
      operations = operations.where(:bank_account_id.in => bank_accounts.distinct(:_id))
    end
    operations
  end
end
