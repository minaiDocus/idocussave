# -*- encoding : UTF-8 -*-
class Knowings < ApplicationRecord
  belongs_to :organization

  attr_encrypted :url,      random_iv: true
  attr_encrypted :username, random_iv: true
  attr_encrypted :password, random_iv: true

  validates_url :url, allow_blank: true, message: I18n.t('activemodel.errors.messages.invalid')

  validates_presence_of :url,       if: :active?
  validates_presence_of :username,  if: :active?
  validates_presence_of :password,  if: :active?
  validates_presence_of :pole_name, if: :active?


  state_machine :state, initial: :not_performed, namespace: 'configuration' do
    state :valid
    state :invalid
    state :verifying
    state :not_performed

    after_transition on: :verify, do: :process_verification

    event :reinit do
      transition all => :not_performed
    end

    event :verify do
      transition [:invalid, :not_performed] => :verifying
    end

    event :invalid do
      transition all => :invalid
    end

    event :valid do
      transition all => :valid
    end
  end


  def active?
    is_active
  end


  def configured?
    configuration_valid?
  end
  alias is_configured? configured?


  def ready?
    is_configured? && active?
  end


  def configuration_changed?
    username_changed? || password_changed? || url_changed? || is_active_changed?
  end

  def client
    @client ||= KnowingsApi::Client.new(username, password, url)
  end

  def process_verification
    if client.verify
      valid_configuration
    else
      invalid_configuration
    end
  end


  class UnexpectedResponseCode < RuntimeError; end
end
