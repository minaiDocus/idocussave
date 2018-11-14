# -*- encoding : UTF-8 -*-
class Retriever < ActiveRecord::Base
  attr_accessor :confirm_dyn_params, :check_journal

  belongs_to :user
  belongs_to :journal,               class_name: 'AccountBookType'
  belongs_to :connector
  has_many   :temp_documents
  has_many   :bank_accounts
  has_many   :sandbox_documents
  has_many   :sandbox_bank_accounts

  serialize :old_param1
  serialize :old_param2
  serialize :old_param3
  serialize :old_param4
  serialize :old_param5
  serialize :additionnal_fields
  serialize :old_answers
  serialize :budgea_additionnal_fields
  serialize :fiduceo_additionnal_fields
  serialize :capabilities

  attr_encrypted :param1,  random_iv: true, type: :json
  attr_encrypted :param2,  random_iv: true, type: :json
  attr_encrypted :param3,  random_iv: true, type: :json
  attr_encrypted :param4,  random_iv: true, type: :json
  attr_encrypted :param5,  random_iv: true, type: :json
  attr_encrypted :answers, random_iv: true, type: :json

  validates :encrypted_param1,  symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_param1.nil? }
  validates :encrypted_param2,  symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_param2.nil? }
  validates :encrypted_param3,  symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_param3.nil? }
  validates :encrypted_param4,  symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_param4.nil? }
  validates :encrypted_param5,  symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_param5.nil? }
  validates :encrypted_answers, symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_answers.nil? }

  validates_presence_of :name
  validates_presence_of :connector_id
  validate :presence_of_dyn_params,    if: :confirm_dyn_params
  validate :presence_of_answers,       if: Proc.new { |r| r.answers.present? }
  validate :presence_of_journal

  before_validation do |retriever|
    if retriever.connector
      retriever.service_name = retriever.connector.name
      retriever.capabilities = retriever.connector.capabilities
    end
    retriever.journal = nil if retriever.capabilities == ['bank']
  end

  before_save do |retriever|
    if retriever.journal_id.nil?
      retriever.journal_name = nil
    elsif retriever.journal_id_changed?
      retriever.journal_name = retriever.journal.name
    end

    retriever.temp_documents.update_all(retriever_name: retriever.name) if retriever.name_changed?
  end

  after_create do |retriever|
    if retriever.configuring?
      retriever.configure_budgea_connection  if retriever.connector.is_budgea_active?
      retriever.configure_fiduceo_connection if retriever.connector.is_fiduceo_active?
    end
  end

  scope :new_password_needed,      -> { where(is_new_password_needed: true) }
  scope :ready,                    -> { where(state: 'ready') }
  scope :waiting_selection,        -> { where(state: 'waiting_selection') }
  scope :waiting_additionnal_info, -> { where(state: 'waiting_additionnal_info') }
  scope :error,                    -> { where(state: 'error') }
  scope :unavailable,              -> { where(state: 'unavailable') }
  scope :not_processed,            -> { where(state: %w(configuring destroying running)) }
  scope :insane,                   -> { where(state: 'ready', is_sane: false) }

  scope :providers,           -> { where("capabilities LIKE '%document%'") }
  scope :banks,               -> { where("capabilities LIKE '%bank%'") }
  scope :providers_and_banks, -> { where("capabilities LIKE '%document%' AND capabilities LIKE '%bank%'") }

  state_machine initial: :configuring do
    state :ready
    state :configuring
    state :destroying
    state :running
    state :waiting_selection
    state :waiting_additionnal_info
    state :error
    state :unavailable

    before_transition :error => :ready do |retriever, transition|
      retriever.error_message = nil
    end

    before_transition any => [:ready, :error, :waiting_additionnal_info] do |retriever, transition|
      5.times do |i|
        param_name = "param#{i+1}"
        param = retriever.send(param_name)
        if param && param['type'] != 'list' && !param['name'].in?(%w(login username name email mail merchant_id))
          retriever.send("#{param_name}=", nil)
        end
      end
    end

    before_transition any => [:ready, :error] do |retriever, transition|
      retriever.additionnal_fields = nil
      retriever.answers            = nil
    end

    after_transition any => [:configuring, :running, :destroying] do |retriever, transition|
      retriever.synchronize_budgea_connection  if retriever.connector.is_budgea_active?
      retriever.synchronize_fiduceo_connection if retriever.connector.is_fiduceo_active?
    end

    event :ready do
      transition [:configuring, :running, :waiting_selection, :error] => :ready
    end

    event :configure_connection do
      transition [:ready, :waiting_additionnal_info, :error] => :configuring
    end

    event :destroy_connection do
      transition any => :destroying
    end

    event :run do
      transition [:ready, :error] => :running
    end

    event :wait_selection do
      transition [:ready] => :waiting_selection
    end

    event :wait_additionnal_info do
      transition [:ready, :error, :configuring] => :waiting_additionnal_info
    end

    event :error do
      transition [:ready, :configuring, :destroying, :running] => :error
    end

    event :unavailable do
      transition any => :unavailable
    end
  end

  state_machine :budgea_state, initial: :not_configured, namespace: :budgea_connection do
    state :not_configured
    state :successful
    state :failed
    state :synchronizing
    state :destroyed
    state :paused # waiting additionnal information from user

    before_transition any => :successful do |retriever, transition|
      retriever.budgea_error_message = nil
    end

    after_transition any => :successful do |retriever, transition|
      if retriever.fiduceo_connection_successful? || retriever.fiduceo_connection_not_configured?
        retriever.ready
      end
    end

    after_transition any => :failed do |retriever, transition|
      if retriever.fiduceo_connection_successful? || retriever.fiduceo_connection_not_configured?
        retriever.error_message = retriever.budgea_error_message
        retriever.error
      elsif retriever.fiduceo_connection_failed?
        retriever.error_message = retriever.fiduceo_error_message
        retriever.error
      end
    end

    after_transition any => :destroyed do |retriever, transition|
      if retriever.fiduceo_connection_destroyed? || retriever.fiduceo_connection_not_configured?
        retriever.destroy
      end
    end

    after_transition any => :paused do |retriever, transition|
      if retriever.fiduceo_connection_paused? || retriever.fiduceo_connection_not_configured?
        retriever.additionnal_fields = retriever.budgea_additionnal_fields
        retriever.wait_additionnal_info
      end
    end

    event :configure do
      transition :not_configured => :synchronizing
    end

    event :synchronize do
      transition [:successful, :failed, :paused] => :synchronizing
    end

    event :fail do
      transition [:synchronizing, :paused, :successful] => :failed
    end

    event :success do
      transition [:synchronizing, :failed] => :successful
    end

    event :pause do
      transition [:synchronizing, :successful] => :paused
    end

    event :destroy do
      transition :synchronizing => :destroyed
    end
  end

  state_machine :fiduceo_state, initial: :not_configured, namespace: :fiduceo_connection do
    state :not_configured
    state :successful
    state :failed
    state :synchronizing
    state :destroyed
    state :paused # waiting additionnal information from user

    before_transition any => :successful do |retriever, transition|
      retriever.fiduceo_error_message = nil
    end

    after_transition any => :successful do |retriever, transition|
      if retriever.budgea_connection_successful? || retriever.budgea_connection_not_configured?
        retriever.ready
      end
    end

    after_transition any => :failed do |retriever, transition|
      if retriever.budgea_connection_successful? || retriever.budgea_connection_not_configured?
        retriever.error_message = retriever.budgea_error_message
        retriever.error
      elsif retriever.budgea_connection_failed?
        retriever.error_message = retriever.budgea_error_message
        retriever.error
      end
    end

    after_transition any => :destroyed do |retriever, transition|
      if retriever.budgea_connection_destroyed? || retriever.budgea_connection_not_configured?
        retriever.destroy
      end
    end

    after_transition any => :paused do |retriever, transition|
      if retriever.budgea_connection_paused? || retriever.budgea_connection_not_configured?
        retriever.additionnal_fields = retriever.budgea_additionnal_fields
        retriever.wait_additionnal_info
      end
    end

    event :configure do
      transition :not_configured => :synchronizing
    end

    event :synchronize do
      transition [:successful, :failed, :paused] => :synchronizing
    end

    event :fail do
      transition [:synchronizing, :paused, :successful] => :failed
    end

    event :success do
      transition [:synchronizing, :failed] => :successful
    end

    event :pause do
      transition [:synchronizing, :successful] => :paused
    end

    event :destroy do
      transition :synchronizing => :destroyed
    end
  end

  class << self
    def search(contains)
      retrievers = Retriever.all

      user_ids = []

      if contains[:user_code].present?
        user_ids = User.where("code LIKE ?", "%#{contains[:user_code]}%").pluck(:id)
      end

      if contains[:created_at]
        contains[:created_at].each do |operator, value|
          retrievers = retrievers.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:updated_at]
        contains[:updated_at].each do |operator, value|
          retrievers = retrievers.where("updated_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      retrievers = retrievers.where(user_id:               user_ids)                       if user_ids.any?
      retrievers = retrievers.where(is_sane:               contains[:is_sane])             if contains[:is_sane].present?
      retrievers = retrievers.where("name LIKE ?",         "%#{contains[:name]}%")         if contains[:name].present?
      retrievers = retrievers.where("state LIKE ?",        "%#{contains[:state]}%")        if contains[:state].present?
      retrievers = retrievers.where("service_name LIKE ?", "%#{contains[:service_name]}%") if contains[:service_name].present?

      if contains[:capabilities].present?
        if contains[:capabilities] == 'both'
          retrievers = retrievers.where("capabilities LIKE '%document%' AND capabilities LIKE '%bank%'")
        else
          retrievers = retrievers.where("capabilities LIKE ?", "%#{contains[:capabilities]}%")
        end
      end

      retrievers
    end

    def search_for_collection(collection, contains)
      collection = collection.where(state: contains[:state]) unless contains[:state].blank?
      collection = collection.where('name LIKE ?', "%#{contains[:name]}%") unless contains[:name].blank?
      collection
    end
  end

  def processing?
    configuring? || running?
  end

  def provider?
    capabilities == ['document']
  end

  def bank?
    capabilities == ['bank']
  end

  def provider_and_bank?
    capabilities && capabilities.include?('bank') && capabilities.include?('document')
  end

  def not_processed?
    configuring? || destroying? || running?
  end

  def clear_name
    if name != service_name
      "\"#{name}\" (#{service_name})"
    else
      "\"#{name}\""
    end
  end

private

  def presence_of_journal
    if check_journal && (provider? || provider_and_bank?)
      errors.add(:journal, :blank) unless journal_id
    end
  end

  # TODO move into a form service
  def presence_of_dyn_params
    if connector
      5.times do |i|
        param_name = "param#{i+1}"
        param = send(param_name)
        if param
          field = connector.combined_fields[param['name']]
          if field
            send("#{param_name}=", send(param_name).merge('type' => field['type']))
            if param['value'].present?
              if field['type'] == 'list'
                values = field['values'].map { |e| e['value'] }
                unless values.include? param['value']
                  errors.add(param_name, :invalid)
                end
              elsif param['value'].size > 256
                errors.add(param_name, :invalid)
              end
            elsif !field['label'].match /optionnel/
              errors.add(param_name, :blank)
            end
          elsif send(param_name).present?
            send("#{param_name}=", nil)
            errors.add(param_name, :invalid)
          end
        end
      end
    end
  end

  # TODO move into a form service
  def presence_of_answers
    names = additionnal_fields.map { |e| e['name'] }.sort
    if answers.keys.sort == names
      answers.each do |key, value|
        unless value.size > 0 && value.size < 256
          errors.add(:answers, :invalid)
        end
      end
    else
      errors.add(:answers, :invalid)
    end
  end
end
