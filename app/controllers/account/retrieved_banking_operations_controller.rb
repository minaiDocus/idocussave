# -*- encoding : UTF-8 -*-
class Account::RetrievedBankingOperationsController < Account::FiduceoController
  layout 'layouts/account/retrievers'

  def index
    @operations = FiduceoOperation.new(@user.fiduceo_id, banking_operation_contains).operations
  end

private

  def banking_operation_contains
    options = {
      page:         params[:page] || 1,
      per_page:     params[:per_page] || Kaminari.config.default_per_page
    }
    @is_filter_empty = true
    if params[:banking_operation_contains]
      if params[:banking_operation_contains][:label].present?
        options.merge!({ search_label: params[:banking_operation_contains][:label]})
        @is_filter_empty = false
      end
      if params[:banking_operation_contains][:date].present?
        if params[:banking_operation_contains][:date][:from].present? || params[:banking_operation_contains][:date][:to].present?
          params[:banking_operation_contains][:date][:from] = params[:banking_operation_contains][:date][:to]   unless params[:banking_operation_contains][:date][:from].present?
          params[:banking_operation_contains][:date][:to]   = params[:banking_operation_contains][:date][:from] unless params[:banking_operation_contains][:date][:to].present?

          from_date = Time.zone.parse(params[:banking_operation_contains][:date][:from])
          to_date   = Time.zone.parse(params[:banking_operation_contains][:date][:to])

          if from_date && to_date
            to_date = from_date if from_date > to_date

            params[:banking_operation_contains][:date][:from] = from_date.strftime('%Y-%m-%d')
            params[:banking_operation_contains][:date][:to]   = to_date.strftime('%Y-%m-%d')

            options.merge!({ from_date: from_date.strftime('%d/%m/%Y'), to_date: to_date.strftime('%d/%m/%Y') })
            @is_filter_empty = false
          else
            params[:banking_operation_contains][:date][:from] = nil
            params[:banking_operation_contains][:date][:to]   = nil
          end
        end
      end
    end
    options
  end
  helper_method :banking_operation_contains
end
