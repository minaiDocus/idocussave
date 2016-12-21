# -*- encoding : UTF-8 -*-
class FiduceoConnector
  class << self
    def banks
      Rails.cache.fetch 'fiduceo_connector_banks', expires_in: 1.day, compress: true do
        get 'banks'
      end
    end

    def providers
      Rails.cache.fetch 'fiduceo_connector_providers', expires_in: 1.day, compress: true do
        get 'providers'
      end
    end

    def get(type)
      results = Fiduceo.send(type)
      if Fiduceo.response.code == 200
        results.select do |data|
          data.deleted != 'true'
        end.map do |data|
          connector = {
            name:   data.name,
            type:   type.singularize,
            id:     data.provider_id,
            inputs: data.inputs['input']
          }
          if data.provider_infos && data.provider_infos['providerInfo']
            if data.provider_infos['providerInfo'].is_a? Array
              connector[:url] = data.provider_infos['providerInfo'][0]['libelle']
            elsif data.provider_infos['providerInfo'].is_a? Hash
              connector[:url] = data.provider_infos['providerInfo']['libelle']
            else
              connector[:url] = nil
            end
          end
          connector.with_indifferent_access
        end.sort do |connector1, connector2|
          connector1[:name].downcase <=> connector2[:name].downcase
        end
      else
        raise Fiduceo::Errors::ServiceUnavailable.new('banks')
      end
    end

    def flush_all_cache
      flush_banks_cache
      flush_providers_cache
    end

    def flush_banks_cache
      Rails.cache.delete('fiduceo_connector_banks')
    end

    def flush_providers_cache
      Rails.cache.delete('fiduceo_connector_providers')
    end

    def all
      banks + providers
    end

    def find(id)
      all.select{ |e| e[:id] == id }.first
    end
  end
end
