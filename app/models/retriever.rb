# -*- encoding : UTF-8 -*-
class Retriever
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :confirm_dyn_params

  belongs_to :user
  belongs_to :journal,               class_name: 'AccountBookType'
  belongs_to :connector
  has_many   :temp_documents
  has_many   :bank_accounts
  has_many   :sandbox_documents
  has_many   :sandbox_bank_accounts

  field :budgea_id,              type: Integer
  field :fiduceo_id
  field :fiduceo_transaction_id
  field :name
  # TODO encrypt
  field :param1,                 type: Hash
  field :param2,                 type: Hash
  field :param3,                 type: Hash
  field :param4,                 type: Hash
  field :param5,                 type: Hash
  field :additionnal_fields,     type: Array
  field :answers,                type: Hash
  field :journal_name
  field :sync_at,                type: Time
  field :is_sane,                type: Boolean, default: true
  field :is_new_password_needed, type: Boolean, default: false
  field :is_selection_needed,    type: Boolean, default: true
  field :state
  field :error_message

  field :budgea_state
  field :budgea_additionnal_fields
  field :budgea_error_message

  field :fiduceo_state
  field :fiduceo_additionnal_fields
  field :fiduceo_error_message

  index({ state: 1 })

  validates_presence_of :name
  validates_presence_of :journal,      if: Proc.new { |r| r.provider? || r.provider_and_bank? }
  validates_presence_of :connector_id
  validate :presence_of_dyn_params,    if: :confirm_dyn_params
  validate :presence_of_answers,       if: Proc.new { |r| r.answers.present? }

  before_validation do |retriever|
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
  scope :not_processed,            -> { where(:state.in => %w(configuring destroying running)) }
  scope :insane,                   -> { where(state: 'ready', is_sane: false) }

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
    def providers
      connector_ids = Connector.where(capabilities: 'document').distinct(:_id)
      where(:connector_id.in => connector_ids)
    end

    def banks
      connector_ids = Connector.where(capabilities: 'bank').distinct(:_id)
      where(:connector_id.in => connector_ids)
    end

    def providers_and_banks
      connector_ids = Connector.where(:capabilities.all => %w(document bank)).distinct(:_id)
      where(:connector_id.in => connector_ids)
    end
  end

  def processing?
    configuring? || running?
  end

  def provider?
    capabilities && capabilities == ['document']
  end

  def bank?
    capabilities && capabilities == ['bank']
  end

  def provider_and_bank?
    capabilities && capabilities.include?('bank') && capabilities.include?('document')
  end

  def capabilities
    connector.try(:capabilities)
  end

  def service_name
    connector.try(:name)
  end

private

  # TODO move into a form service
  def presence_of_dyn_params
    if connector
      5.times do |i|
        param_name = "param#{i+1}"
        param = send(param_name)
        if param
          field = connector.combined_fields[param['name']]
          if field
            send(param_name)['type'] = field['type']
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
