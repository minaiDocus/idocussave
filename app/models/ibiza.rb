# -*- encoding : UTF-8 -*-
class Ibiza
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization

  field :token, type: String
  field :state, type: String, default: 'none'

  field :description,           type: Hash,    default: {}
  field :description_separator, type: String,  default: ' - '
  field :piece_name_format,     type: Hash,    default: {}
  field :piece_name_format_sep, type: String,  default: ' '
  field :is_auto_deliver,       type: Boolean, default: false

  validates_inclusion_of :state, in: %w(none waiting valid invalid)

  def is_configured?
    state == 'valid'
  end

  def client
    @_client ||= IbizaAPI::Client.new(self.token)
  end

  def set_state
    if token.present?
      update(state: 'waiting')
      verify_token
    else
      update(state: 'none')
    end
  end

  def verify_token
    client.request.clear
    client.company?
    if client.response.success?
      update(state: 'valid')
    else
      update(state: 'invalid')
    end
  end
  handle_asynchronously :verify_token, queue: 'ibiza token verification', priority: 0

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
    Rails.cache.write([:ibiza, id, :users], result)
    result
  end
  handle_asynchronously :get_users, queue: 'ibiza get users', priority: 1

  def flush_users_cache
    Rails.cache.delete([:ibiza, id, :users])
  end

  def auto_assign_users
    get_users_without_delay
    if users
      organization.customers.each do |customer|
        if (e = users.select { |e| e.name == customer.company }.first)
          customer.update_attribute(:ibiza_id, e.id)
        end
      end
    end
  end
end
