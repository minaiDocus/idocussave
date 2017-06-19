# -*- encoding : UTF-8 -*-
class Box < ActiveRecord::Base
  belongs_to :external_file_storage

  attr_encrypted :refresh_token, random_iv: true
  attr_encrypted :access_token,  random_iv: true

  def get_authorize_url
    session.authorize_url(Box.config.callback_url)
  end

  def get_access_token(code)
    result   = session.get_access_token(code)
    @session = nil

    update(access_token: result.token, refresh_token: result.refresh_token, is_configured: true)
  end

  def client
    @client ||= RubyBox::Client.new(session)
  end

  def is_configured?
    is_configured
  end

  def session
    if @session
      @session
    else
      options = {
        client_id:     Box.config.client_id,
        client_secret: Box.config.client_secret
      }

      options[:access_token] = access_token if access_token.present?

      @session = RubyBox::Session.new options
    end
  end

  def reset_session
    update(access_token: nil, refresh_token: nil, is_configured: false)
  end

  class << self
    def configure
      yield config
    end

    def config
      @@config ||= Configuration.new
    end
  end

  class Configuration
    attr_accessor :client_id, :client_secret, :callback_url

    def initialize
      @client_id     = Rails.application.secrets.box_api['client_id']
      @client_secret = Rails.application.secrets.box_api['client_secret']
      @callback_url  = Rails.application.secrets.box_api['callback_url']
    end
  end
end
