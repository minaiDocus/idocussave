# -*- encoding : UTF-8 -*-
class ExactOnline < ActiveRecord::Base
  belongs_to :organization

  attr_encrypted :access_token,    random_iv: true
  attr_encrypted :refresh_token,   random_iv: true

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

  def is_session_expired?
    self.token_expires_at <= 30.seconds.from_now
  end

  # TODO manage timeout, internal server error and service unavailable
  def refresh_session
    self.with_lock(timeout: 60, retries: 120, retry_sleep: 0.5) do
      if self.token_expires_at <= 10.seconds.from_now
        session.refresh_tokens
        self.refresh_token     = session.refresh_token
        self.access_token      = session.access_token
        self.token_expires_at  = session.expires_at
        self.save
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
    @session ||= ExactOnlineSdk::Session.new({
      refresh_token: self.refresh_token,
      access_token:  self.access_token,
      expires_at:    self.token_expires_at
    })
  end

  def client(division=nil)
    @client ||= ExactOnlineSdk::Client.new(session, division)
  end

  def reset
    self.refresh_token    = nil
    self.access_token     = nil
    self.token_expires_at = nil
    self.user_name        = nil
    self.email            = nil
    self.full_name        = nil
    self.is_auto_deliver  = false
    self.save
    self.deactivate
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

  def used?
    self.access_token.present? && self.configured?
  end
end
