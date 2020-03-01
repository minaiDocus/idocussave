# -*- encoding : UTF-8 -*-
module DropboxExtended
  class << self
    def authenticator
      DropboxApi::Authenticator.new(
        Rails.application.credentials[Rails.env.to_sym][:dropbox_extended_api][:key],
        Rails.application.credentials[Rails.env.to_sym][:dropbox_extended_api][:secret]
      )
    end

    def get_authorize_url
      authenticator.authorize_url
    end

    def get_access_token(code)
      auth_bearer = authenticator.get_token code
      auth_bearer.token
    end

    def access_token
      Rails.application.credentials[Rails.env.to_sym][:dropbox_extended_api][:access_token]
    end

    def client
      DropboxApi::Client.new(access_token)
    end
  end
end
