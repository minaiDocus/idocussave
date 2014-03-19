class FiduceoProvider
  attr_accessor :user_id

  def initialize(user_id)
    @user_id = user_id
    Rails.cache.fetch(['fiduceo_provider_cache_list']) { [] }
  end

  def banks
    if @user_id
      cache_name = "fiduceo_#{user_id}_banks"
      result = Rails.cache.read(cache_name)
      if result.is_a? Array
        result
      else
        results = client.banks
        if client.response.code == 200
          results = results[1].map do |bank|
            _bank = {
              name: bank.name,
              type: 'bank',
              wait_for_user: bank.wait_for_user == 'true' ? true : false,
              wait_for_user_label: bank.wait_for_user_label == 'NONE' ? nil : bank.wait_for_user_label
            }.with_indifferent_access
            _bank['id']     = bank.provider_id
            _bank['inputs'] = bank.inputs['input']
            _bank
          end
        end
        register_to_cache_list cache_name
        Rails.cache.write(cache_name, results, :expires_in => 7.days, :compress => true)
        results
      end
    else
      []
    end
  end

  def flush_banks_cache
    Rails.cache.delete(['fiduceo', user_id, 'banks'])
    Rails.cache.delete(['fiduceo', user_id, 'raw_banks'])
  end

  def providers
    FiduceoProvider.providers
  end

  class << self
    def flush_all_cache
      list = Rails.cache.fetch(['fiduceo_provider_cache_list']) { [] }
      list.each do |cache_name|
        Rails.cache.delete cache_name
      end
      flush_providers_cache
      Rails.cache.delete(['fiduceo_provider_cache_list'])
    end

    def flush_providers_cache
      Rails.cache.delete('fiduceo_provider_providers')
      Rails.cache.delete('fiduceo_provider_raw_providers')
    end

    def providers
      Rails.cache.fetch('fiduceo_provider_providers', :expires_in => 7.days, :compress => true) do
        results = Fiduceo.providers
        if results.class == Array
          Rails.cache.write('fiduceo_provider_raw_providers', results, :expires_in => 7.days, :compress => true)
          results.map do |provider|
            _provider = {
              name: provider.name,
              type: 'provider',
              wait_for_user: provider.wait_for_user == 'true' ? true : false,
              wait_for_user_label: provider.wait_for_user_label == 'NONE' ? nil : provider.wait_for_user_label
            }.with_indifferent_access
            _provider['id'] = provider.id
            _provider['inputs'] = provider.inputs['input']
            _provider
          end
        else
          []
        end
      end
    end
  end

private

  def client
    @client ||= Fiduceo::Client.new @user_id
  end

  def register_to_cache_list(cache_name)
    new_value = (Rails.cache.read('fiduceo_provider_cache_list') + [cache_name]).uniq
    Rails.cache.write('fiduceo_provider_cache_list', new_value)
  end
end
