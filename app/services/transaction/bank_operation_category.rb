# -*- encoding : UTF-8 -*-
class Transaction::BankOperationCategory
  class << self
    def all
      Rails.cache.fetch(['bank_operation_categories', 'all'], :expires_in => 7.days, :compress => true) do
        client = Budgea::Client.new
        categories = client.get_categories
        client.response.status == 200 ? categories : []
      end
    end

    def flush_cache
      Rails.cache.delete ['bank_operation_categories', 'all']
    end

    def find(id)
      result = nil
      all.each do |category|
        if category['id'] == id
          result = category
        elsif category['children'].present?
          category['children'].each do |child|
            if child['id'] == id
              result = child
              break
            end
          end
        end
        break if result
      end
      result
    end
  end
end
