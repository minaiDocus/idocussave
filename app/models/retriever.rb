# -*- encoding : UTF-8 -*-
class Retriever
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :confirm_dyn_params

  belongs_to :user
  belongs_to :journal,        class_name: 'AccountBookType'
  has_many   :retriever_transactions
  has_many   :temp_documents
  has_many   :bank_accounts

  field :api_id,                 type: Integer
  field :provider_id,            type: Integer
  field :bank_id,                type: Integer
  field :service_name
  field :type,                                  default: 'provider'
  field :name
  # TODO encrypt
  field :param1,                 type: Hash
  field :param2,                 type: Hash
  field :param3,                 type: Hash
  field :param4,                 type: Hash
  field :additionnal_fields,     type: Array
  field :answers,                type: Hash
  field :journal_name
  field :sync_at,                type: Time
  field :is_sane,                type: Boolean, default: true
  field :is_new_password_needed, type: Boolean, default: false
  field :is_selection_needed,    type: Boolean, default: true
  field :error_message
  field :state

  index({ state: 1 })

  validates_presence_of  :type, :name, :service_name
  validates_inclusion_of :type, in: %w(provider bank)
  validates_presence_of  :journal, if: :provider?
  validate :truthfullness_of_connector_id
  validate :presence_of_dyn_params, if: :confirm_dyn_params

  scope :providers,           -> { where(type: 'provider') }
  scope :banks,               -> { where(type: 'bank') }
  scope :new_password_needed, -> { where(is_new_password_needed: true) }

  scope :ready,                    -> { where(state: 'ready') }
  scope :waiting_selection,        -> { where(state: 'waiting_selection') }
  scope :waiting_additionnal_info, -> { where(state: 'waiting_additionnal_info') }
  scope :error,                    -> { where(state: 'error') }
  scope :unavailable,              -> { where(state: 'unavailable') }
  scope :not_processed,            -> { where(:state.in => %w(creating updating destroying synchronizing)) }
  scope :insane,                   -> { where(state: 'ready', is_sane: false) }

  state_machine initial: :creating do
    state :ready
    state :creating
    state :updating
    state :destroying
    state :synchronizing
    state :waiting_selection
    state :waiting_additionnal_info
    state :error
    state :unavailable

    before_transition :error => :ready do |retriever, transition|
      retriever.error_message = nil
    end

    before_transition any => [:ready, :error, :waiting_additionnal_info] do |retriever, transition|
      4.times do |i|
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

    event :ready do
      transition [:creating, :updating, :synchronizing, :waiting_selection, :error] => :ready
    end

    event :create_connection do
      transition :error => :creating
    end

    event :update_connection do
      transition [:ready, :waiting_additionnal_info, :error] => :updating
    end

    event :destroy_connection do
      transition any => :destroying
    end

    event :synchronize do
      transition [:ready, :error] => :synchronizing
    end

    event :wait_selection do
      transition [:ready] => :waiting_selection
    end

    event :wait_additionnal_info do
      transition [:creating, :updating] => :waiting_additionnal_info
    end

    event :error do
      transition [:ready, :creating, :updating, :destroying, :synchronizing] => :error
    end

    event :unavailable do
      transition any => :unavailable
    end
  end

  before_save do |retriever|
    if retriever.type == 'provider'
      retriever.bank_id = nil
    else
      retriever.provider_id = nil
    end
  end

  before_validation do |retriever|
    retriever.service_name ||= connector[:name]
  end

  def connector_id
    provider_id || bank_id
  end

  def provider?
    type == 'provider'
  end

  def bank?
    type == 'bank'
  end

private

  def truthfullness_of_connector_id
    unless connector
      errors.add("#{type}_id", :invalid)
    end
  end

  def presence_of_dyn_params
    if connector
      4.times do |i|
        param_name = "param#{i+1}"
        param = send(param_name)
        field = connector[:fields][i]
        if field
          if param['name'] == field['name']
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
          else
            errors.add(param_name, :invalid)
          end
        elsif send(param_name).present?
          send(param_name, nil)
        end
      end
    end
  end

  def connector
    @connector ||= RetrieverProvider.find(connector_id)
  end
end