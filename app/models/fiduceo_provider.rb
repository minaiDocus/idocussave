class FiduceoProvider
  attr_accessor :user_id

  def initialize(user)
    if user.is_a? User
      @user_id = user.fiduceo_id
    elsif user.is_a? String
      @user_id = user
    end
  end

  def list
    Rails.cache.fetch(['fiduceo', user_id, 'list'], :expires_in => 7.days, :compress => true) do
      (banks + providers).uniq.sort do |a,b|
        (a['type'] + a['name']) <=> (b['type'] + b['name'])
      end
    end
  end

  def clear_list_cache
    Rails.cache.delete(['fiduceo', user_id, 'list'])
  end

  def banks
    if @user_id
      Rails.cache.fetch(['fiduceo', user_id, 'banks'], :expires_in => 7.days, :compress => true) do
        result = client.banks
        if result.class == Array
          Rails.cache.write(['fiduceo', user_id, 'raw_banks'], result, :expires_in => 7.days, :compress => true)
          result.map do |bank|
            _bank = { name: bank.name, type: 'bank' }
            _bank['id']     = bank.providerId
            _bank['inputs'] = bank.inputs['input']
            _bank
          end
        else
          []
        end
      end
    else
      []
    end
  end

  def clear_banks_cache
    Rails.cache.delete(['fiduceo', user_id, 'banks'])
    Rails.cache.delete(['fiduceo', user_id, 'raw_banks'])
  end

  def providers
    Rails.cache.fetch('fiduceo_provider_providers', :expires_in => 7.days, :compress => true) do
      result = Fiduceo.providers
      if result.class == Array
        Rails.cache.write('fiduceo_provider_raw_providers', result, :expires_in => 7.days, :compress => true)
        result.map do |provider|
          _provider = { name: provider.name, type: 'provider' }
          _provider['id'] = provider.id
          _provider['inputs'] = provider.inputs['input']
          _provider
        end
      else
        []
      end
    end
  end

  def clear_providers_cache
    Rails.cache.delete('fiduceo_provider_providers')
    Rails.cache.delete('fiduceo_provider_raw_providers')
  end

private

  def client
    @client ||= Fiduceo::Client.new @user_id
  end
end
