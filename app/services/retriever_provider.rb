class RetrieverProvider
  def banks
    Rails.cache.fetch('retriever_provider_banks', :expires_in => 1.day, :compress => true) do
      banks = client.get_banks
      if client.response.code == 200
        banks.select do |bank|
          bank['hidden'] == false
        end.sort_by do |bank|
          bank['name'].downcase
        end.map do |bank|
          bank.slice!('id', 'name', 'capabilities', 'fields')
          bank['capabilities'] = bank['capabilities'].select { |e| e.in? %w(bank document) }
          bank.with_indifferent_access
        end
      else
        raise Budgea::Errors::ServiceUnavailable.new('banks')
      end
    end
  end

  def providers
    Rails.cache.fetch('retriever_provider_providers', :expires_in => 1.day, :compress => true) do
      providers = client.get_providers
      if client.response.code == 200
        providers.select do |provider|
          provider['hidden'] == false
        end.sort_by do |provider|
          provider['name'].downcase
        end.map do |provider|
          provider.slice!('id', 'name', 'capabilities', 'fields')
          provider['capabilities'] = provider['capabilities'].select { |e| e.in? %w(bank document) }
          provider.with_indifferent_access
        end
      else
        raise Budgea::Errors::ServiceUnavailable.new('providers')
      end
    end
  end

  class << self
    def flush_banks_cache
      Rails.cache.delete('retriever_provider_banks')
    end

    def flush_providers_cache
      Rails.cache.delete('retriever_provider_providers')
    end

    def flush_all_cache
      flush_banks_cache
      flush_providers_cache
    end

    def find(id)
      rp = RetrieverProvider.new
      list = rp.providers + rp.banks
      list.select{ |e| e[:id] == id }.first
    end
  end

private

  def client
    @client ||= Budgea::Client.new
  end
end
