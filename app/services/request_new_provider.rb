# -*- encoding : UTF-8 -*-
class RequestNewProvider
  def initialize(new_provider_request_id)
    @new_provider_request = NewProviderRequest.find new_provider_request_id
  end

  def execute
    if CreateBudgeaAccount.execute(@new_provider_request.user)
      result = client.request_new_connector(params)
      if client.response.code == 200
        @new_provider_request.update(api_id: result['id'], password: nil)
      else
        raise RuntimeException
      end
    else
      raise RuntimeException
    end
  end

private

  def client
    @client ||= Budgea::Client.new(@new_provider_request.user.budgea_account.access_token)
  end

  def params
    hsh = {
      api:      Budgea.config.domain,
      bank:     @new_provider_request.name,
      url:      @new_provider_request.url,
      email:    @new_provider_request.email,
      login:    @new_provider_request.login,
      password: @new_provider_request.password,
      types:    @new_provider_request.types,
      comment:  @new_provider_request.description
    }
    hsh.merge!({ identifier: @new_provider_request.api_id }) if @new_provider_request.api_id.present?
    hsh
  end
end
