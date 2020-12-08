class Software::ExactOnline < ApplicationRecord
  include Interfaces::Software::Configuration

  belongs_to :owner, polymorphic: true

  attr_encrypted :client_id,       random_iv: true
  attr_encrypted :client_secret,   random_iv: true
  attr_encrypted :access_token,    random_iv: true
  attr_encrypted :refresh_token,   random_iv: true

  validates_inclusion_of :auto_deliver, in: [-1, 0, 1]

  state_machine :initial => :not_configured do
    state :not_configured
    state :verifying
    state :configured
    state :error
    state :deactivated

    event :not_configured do
      transition [:configured, :deactivated, :error] => :not_configured
    end

    event :verifying do
      transition [:not_configured, :configured, :deactivated, :error] => :verifying
    end

    event :configured do
      transition :verifying => :configured
    end

    event :error do
      transition [:verifying, :configured] => :error
    end

    event :deactivate do
      transition [:error, :configured] => :deactivated
    end
  end

  def reset
    self.refresh_token    = nil
    self.access_token     = nil
    self.token_expires_at = nil
    self.user_name        = nil
    self.email            = nil
    self.full_name        = nil
    self.save
    self.deactivate
  end

  def fully_configured?
    api_keys_present? && linked?
  end

  def api_keys
    {client_id: client_id, client_secret: client_secret}
  end

  def api_keys_present?
    self.client_id.present? && self.client_secret.present?
  end

  def linked?
    self.access_token.present? && self.configured?
  end

  def is_session_expired?
    self.token_expires_at <= 30.seconds.from_now
  end

  # TODO manage timeout, internal server error and service unavailable
  def refresh_session
    self.with_lock(timeout: 60, retries: 120, retry_sleep: 0.5) do
      if self.token_expires_at <= 10.seconds.from_now
        begin
          session.refresh_tokens
          self.refresh_token     = session.refresh_token
          self.access_token      = session.access_token
          self.token_expires_at  = session.expires_at
          self.save
        rescue ExactOnlineLib::Api::Sdk::AuthError
          @session = nil
        end
      else
        @session = nil
      end
      @client = nil
    end
  end

  def refresh_session_if_needed
    refresh_session if is_session_expired?
  end

  def session
    @session ||= ExactOnlineLib::Api::Sdk::Session.new({
      refresh_token: self.refresh_token,
      access_token:  self.access_token,
      expires_at:    self.token_expires_at,
      client_id:     self.client_id,
      client_secret: self.client_secret
    })
  end

  def client(division=nil)
    @client ||= ExactOnlineLib::Api::Sdk::Client.new(session, division)
  end

  def users
    result = Rails.cache.read([:exact_online, id, :users])
    return result if result

    refresh_session_if_needed

    result = client.users.map do |e|
      o = OpenStruct.new
      o.name = e['customer_name']
      o.id = e['customer']
      o
    end

    Rails.cache.write([:exact_online, id, :users], result, expires_in: 5.minutes)
    result
  end
end
