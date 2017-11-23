# -*- encoding : UTF-8 -*-
class Ibiza < ActiveRecord::Base
  serialize :description, Hash
  serialize :piece_name_format, Hash

  attr_encrypted :access_token,   random_iv: true
  attr_encrypted :access_token_2, random_iv: true

  belongs_to :organization


  validates_inclusion_of :state, :state_2, in: %w(none waiting valid invalid)


  before_save :update_states


  def configured?
    state == 'valid' || state_2 == 'valid'
  end


  def two_channel_delivery?
    access_token.present? && access_token_2.present? && access_token != access_token_2
  end


  def need_to_verify_access_tokens?
    state == 'waiting' || state_2 == 'waiting'
  end


  def practical_access_token
    access_token.presence || access_token_2
  end


  def client
    @client ||= IbizaAPI::Client.new(practical_access_token)
  end

  # nil : updating cache
  # [...] : cached values
  # false : error occurs
  def users
    result = Rails.cache.read([:ibiza, id, :users])
    get_users_only_once if result.nil?
    result
  end


  def get_users_only_once
    unless Rails.cache.read([:ibiza, id, :users_is_flushing])
      get_users

      Rails.cache.write([:ibiza, id, :users_is_flushing], true)
    end
  end


  def get_users
    client.request.clear
    client.company?
    result = nil

    if client.response.success?
      result = client.response.data.map do |e|
        o = OpenStruct.new
        o.name = e['name']
        o.id = e['database']
        o
      end
    else
      result = false
    end

    Rails.cache.write([:ibiza, id, :users_is_flushing], false)
    Rails.cache.write([:ibiza, id, :users], result, expires_in: 5.minutes)

    result
  end


  def flush_users_cache
    Rails.cache.delete([:ibiza, id, :users])
  end


  def auto_assign_users
    get_users
    if users
      organization.customers.each do |customer|
        if (e = users.select { |e| e.name == customer.company }.first)
          customer.update_attribute(:ibiza_id, e.id)
        end
      end
    end
  end

  private


  def update_states
    if access_token.present? && access_token_changed?
      self.state = 'waiting'
    elsif !access_token.present?
      self.state = 'none'
    end

    if access_token_2.present? && access_token_2_changed?
      self.state_2 = 'waiting'
    elsif !access_token_2.present?
      self.state_2 = 'none'
    end
  end
end
