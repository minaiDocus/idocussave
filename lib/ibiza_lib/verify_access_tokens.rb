# -*- encoding : UTF-8 -*-
# Calls Ibiza API to check if API token is valid or not
module IbizaLib
  class VerifyAccessTokens
    def initialize(ibiza_id)
      @ibiza_id = ibiza_id
    end

    def execute
      ibiza = Software::Ibiza.find @ibiza_id

      if ibiza.state == 'waiting'
        client = IbizaLib::Api::Client.new(ibiza.access_token, ibiza.specific_url_options)
        client.company?
        if client.response.success?
          ibiza.update(state: 'valid')
        else
          ibiza.update(state: 'invalid')
        end
      end

      if ibiza.state_2 == 'waiting'
        client = IbizaLib::Api::Client.new(ibiza.access_token_2, ibiza.specific_url_options)
        client.company?
        if client.response.success?
          ibiza.update(state_2: 'valid')
        else
          ibiza.update(state_2: 'invalid')
        end
      end

      ibiza.flush_users_cache
    end
  end
end
