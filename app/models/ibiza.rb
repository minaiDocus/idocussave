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

  before_save :set_state, if: Proc.new { |e| 'token'.in?(e.changed) }
  after_update :flush_users_cache, if: Proc.new { |e| 'token'.in?(e.changed) }

  def is_configured?
    state == 'valid'
  end

  def client
    @_client ||= IbizaAPI::Client.new(self.token)
  end

  def set_state
    if self.token.present?
      self.state = 'waiting'
      verify_token
    else
      self.state = 'none'
    end
  end

  def verify_token
    client.company?
    if client.response.success?
      reload
      self.state = 'valid' if self.token.present?
    else
      reload
      self.state = 'invalid' if self.token.present?
    end
    save unless Rails.env == 'test'
  end
  handle_asynchronously :verify_token, queue: 'ibiza token verification', priority: 0

  def self.update_files_for(user_codes)
    users = User.any_in(code: user_codes).entries
    grouped_users = users.group_by { |e| e.organization.try(:id) || e.id }
    grouped_users.each do |e|
      users = e[1]
      organization = users.first.organization
      if organization.ibiza && organization.ibiza.is_configured?
        organization.ibiza.update_files_for users
      end
    end
    true
  end

  def update_files_for(users)
    users.each do |user|
      error_file_path = "#{Rails.root}/data/compta/mapping/#{user.code}.error"
      if user.ibiza_id
        client.request.clear
        client.company(user.ibiza_id).accounts?
        if client.response.success?
          body = client.response.body
          body.force_encoding('UTF-8')
          if File.exist?(error_file_path)
            FileUtils.rm error_file_path
          end
          File.open("#{Rails.root}/data/compta/mapping/#{user.code}.xml",'w') do |f|
            f.write body
          end
        else
          FileUtils.touch error_file_path
        end
      else
        FileUtils.touch error_file_path
      end
    end
    true
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

  def exercices(id)
    Rails.cache.fetch "ibiza_#{id}_exercices", expires_in: 1.hour do
      client.request.clear
      client.company(id).exercices?
      if client.response.success?
        client.response.data
      else
        raise NoExercicesFound, "for #{id}"
      end
    end
  end

  class NoExercicesFound < RuntimeError; end
end
