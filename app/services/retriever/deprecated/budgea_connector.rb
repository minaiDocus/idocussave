# -*- encoding : UTF-8 -*-
class Retriever::BudgeaConnector
  class << self
    def banks
      Rails.cache.fetch 'budgea_connector_banks', expires_in: 1.hours, compress: true do
        get 'banks'
      end
    end

    def providers
      Rails.cache.fetch 'budgea_connector_providers', expires_in: 1.hours, compress: true do
        get 'providers'
      end
    end

    def get(type)
      client = Budgea::Client.new
      connectors = client.send("get_#{type}")
      if client.response.status == 200
        connectors.select do |connector|
          connector['hidden'] == false
        end.sort_by do |connector|
          connector['name'].downcase
        end.map do |connector|
          connector.slice!('id', 'name', 'capabilities', 'fields', 'urls')
          connector['capabilities'] = connector['capabilities'].select { |e| e.in? %w(bank document) }
          connector['urls'] = Array(connector['urls'])
          connector.with_indifferent_access
        end
      else
        raise Budgea::Errors::ServiceUnavailable.new(type)
      end
    end

    def flush_banks_cache
      Rails.cache.delete 'budgea_connector_banks'
    end

    def flush_providers_cache
      Rails.cache.delete 'budgea_connector_providers'
    end

    def flush_all_cache
      flush_banks_cache
      flush_providers_cache
    end

    def all
      (banks + providers).uniq
    end

    def find(id)
      all.select{ |e| e[:id] == id }.first
    end
  end
end
