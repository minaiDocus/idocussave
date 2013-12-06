# -*- encoding : UTF-8 -*-
class FiduceoOperation
  def initialize(user_id, options={})
    @user_id = user_id
    @options = options
  end

  def operations
    results = get_operations
    if results.is_a? Array
      results.each do |result|
        result.date_op = result.date_op.try(:to_time)
        result.amount = result.amount.to_f
        default_category_id = result.amount >= 0 ? 0 : -1
        result.category_id = result.category_id.try(:to_i) || default_category_id
        result.category = FiduceoCategory.find(result.category_id).try(:name)
      end
    else
      results
    end
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

  def client
    @client ||= Fiduceo::Client.new @user_id
  end
end
