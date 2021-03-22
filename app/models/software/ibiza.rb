class Software::Ibiza < ApplicationRecord
  include Interfaces::Software::Configuration

  audited

  serialize :description, Hash
  serialize :piece_name_format, Hash

  attr_encrypted :access_token,   random_iv: true
  attr_encrypted :access_token_2, random_iv: true

  belongs_to :owner, polymorphic: true


  validates_inclusion_of :state, :state_2, in: %w(none waiting valid invalid)
  validates_inclusion_of :voucher_ref_target, in: %w(piece_number piece_name)
  validates_inclusion_of :auto_deliver, :is_analysis_activated, :is_analysis_to_validate, in: [-1, 0, 1]
  validates_inclusion_of :is_auto_updating_accounting_plan, in: [true, false]


  before_validation :update_states

  def configured?
    state == 'valid' || state_2 == 'valid'
  end

  def first_configured?
    state == 'valid'
  end

  def second_configured?
    state_2 == 'valid'
  end

  def two_channel_delivery?
    access_token.present? && access_token_2.present? && access_token != access_token_2
  end

  def need_to_verify_access_tokens?
    state == 'waiting' || state_2 == 'waiting'
  end

  def practical_access_token
    if access_token.present? && state == 'valid'
      access_token
    elsif access_token_2.present? && state_2 == 'valid'
      access_token_2
    end
  end

  def client
    @client ||= IbizaLib::Api::Client.new(practical_access_token, specific_url_options, IbizaLib::ClientCallback.new(self, practical_access_token))
  end

  def first_client
    @client ||= IbizaLib::Api::Client.new(access_token, specific_url_options, IbizaLib::ClientCallback.new(self, access_token))
  end

  def second_client
    @client ||= IbizaLib::Api::Client.new(access_token_2, specific_url_options, IbizaLib::ClientCallback.new(self, access_token_2))
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
      if owner.present? && owner.is_a?(Organization)
        owner.customers.each do |customer|
          if (e = users.select { |e| e.name == customer.company }.first)
            self.update_attribute(:ibiza_id, e.id)
          end
        end
      end
    end
  end

  def compta_analysis_activated?
    (owner.is_a?(User) && is_analysis_activated == -1) ? self.owner.organization.compta_analysis_activated?(self) : (is_analysis_activated == 1)
  end

  # def uses_analytics?
  #   used? && ibiza_id.present? && is_analysis_activated?
  # end

  def ibiza_id?
    ibiza_id.present?
  end

  def analysis_to_validate?
    (owner.is_a?(User) && is_analysis_to_validate == -1) ? self.owner.organization.analysis_to_validate?(self) : (is_analysis_to_validate == 1)
  end

  def auto_update_accounting_plan?
    is_auto_updating_accounting_plan
  end

  private

  def update_states
    self.voucher_ref_target = 'piece_number' if self.voucher_ref_target.blank?

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
