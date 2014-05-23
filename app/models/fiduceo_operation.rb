# -*- encoding : UTF-8 -*-
class FiduceoOperation
  def initialize(user_id, options={})
    @user_id  = user_id
    @page     = options.delete(:page)
    @per_page = options.delete(:per_page)
    @options  = options
  end

  def operations
    if @page.present?
      results = client.operations @page, @per_page, @options
      results = false unless results.is_a?(Array)
    else
      results = get_operations
    end
    results.is_a?(Array) ? format_operations(results) : results
  end

  def by_category
    result = operations
    if result
      result.group_by do |operation|
        operation.category
      end.map do |k,v|
        category = OpenStruct.new
        category.name = k
        category.amount = (v.sum(&:amount) || 0).round
        category.operations = v
        category
      end.sort do |a,b|
        a.name <=> b.name
      end
    else
      result
    end
  end

private

  def get_operations
    per_page = 1000
    results = []
    page = 1
    result = client.operations page, per_page, @options
    if client.response.code == 200
      total = result[0]
      results << result[1]
      if total > result[1].size
        page_number = (total / per_page).ceil
        while page < page_number
          page += 1
          result = client.operations page, per_page, @options
          if client.response.code == 200
            results << result[1]
          else
            results << false
            break
          end
        end
      end
      if results.select { |e| e == false }.first
        false
      else
        results.flatten
      end
    else
      false
    end
  end

  def format_operations(results)
    _operations = results.first.is_a?(Integer) ? results[1] : results
    _operations.each do |operation|
      operation.date_op      = operation.date_op.try(:to_time)
      operation.date_val     = operation.date_val.try(:to_time)
      operation.amount       = operation.amount.to_f
      default_category_id    = operation.amount >= 0 ? 0 : -1
      operation.category_id  = operation.category_id.try(:to_i) || default_category_id
      operation.category     = FiduceoCategory.find(operation.category_id).try(:name)
      operation.bank_account = BankAccount.where(fiduceo_id: operation.account_id).first
    end
    if @page.present?
      _operations = Kaminari.paginate_array(_operations, total_count: results[0]).page(@page).per(@per_page)
    end
    _operations
  end

  def client
    @client ||= Fiduceo::Client.new @user_id
  end
end
