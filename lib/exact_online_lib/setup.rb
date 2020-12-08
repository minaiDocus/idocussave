# -*- encoding : UTF-8 -*-
module ExactOnlineLib
  class Setup
    def initialize(exact_online, code, callback_url)
      if exact_online.is_a? String
        @exact_online = ExactOnline.find exact_online
      else
        @exact_online = exact_online
      end
      @code = code
      @callback_url = callback_url
    end

    def execute
      begin
        session.get_access_token(@code, @callback_url)
        info = client.info '$select' => 'UserName,Email,FullName'
        @exact_online.refresh_token    = session.refresh_token
        @exact_online.access_token     = session.access_token
        @exact_online.token_expires_at = session.expires_at
        @exact_online.user_name        = info['user_name']
        @exact_online.email            = info['email']
        @exact_online.full_name        = info['full_name']
        @exact_online.save
        @exact_online.configured
        true
      rescue ExactOnlineLib::Api::Sdk::AuthError
        @exact_online.error
        false
      end
    end

  private

    def session
      @session ||= ExactOnlineLib::Api::Sdk::Session.new(@exact_online.api_keys)
    end

    def client
      @client ||= ExactOnlineLib::Api::Sdk::Client.new(session)
    end
  end

end
