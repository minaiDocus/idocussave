# -*- encoding : UTF-8 -*-
class Retriever
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :dyn_list_attr, :dyn_pass_attr

  belongs_to :user
  belongs_to :journal,        class_name: 'AccountBookType'
  has_many   :retriever_transactions
  has_many   :temp_documents
  has_many   :bank_accounts

  field :api_id,                       type: Integer
  field :provider_id,                  type: Integer
  field :bank_id,                      type: Integer
  field :service_name
  field :type,                                        default: 'provider'
  field :name
  # TODO verify uniqueness of the couple service_name and login for a user ? (par vs pro....)
  field :login
  # TODO encrypt password, dyn_attr & answers
  field :password
  field :dyn_attr_name
  field :dyn_attr
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

  validates_presence_of  :type, :name, :login, :service_name
  validates_inclusion_of :type, in: %w(provider bank)
  validates_presence_of  :journal, if: :provider?

  scope :providers,           -> { where(type: 'provider') }
  scope :banks,               -> { where(type: 'bank') }
  scope :new_password_needed, -> { where(is_new_password_needed: true) }

  scope :ready,                    -> { where(state: 'ready') }
  scope :waiting_selection,        -> { where(state: 'waiting_selection') }
  scope :waiting_additionnal_info, -> { where(state: 'waiting_additionnal_info') }
  scope :error,                    -> { where(state: 'error') }
  scope :not_processed,            -> { where(:state.in => %w(creating updating destroying synchronizing waiting_data)) }
  scope :insane,                   -> { where(state: 'ready', is_sane: false) }

  state_machine initial: :creating do
    state :ready
    state :creating
    state :updating
    state :destroying
    state :synchronizing
    state :waiting_data
    state :waiting_selection
    state :waiting_additionnal_info
    state :error

    before_transition :error => :ready do |retriever, transition|
      retriever.error_message = nil
    end

    event :ready do
      transition [:creating, :updating, :synchronizing, :waiting_data, :waiting_selection, :error] => :ready
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

    event :wait_data do
      transition [:creating, :updating, :synchronizing] => :waiting_data
    end

    event :wait_selection do
      transition [:waiting_data] => :waiting_selection
    end

    event :wait_additionnal_info do
      transition [:creating, :updating] => :waiting_additionnal_info
    end

    event :error do
      transition [:ready, :creating, :updating, :destroying, :synchronizing, :waiting_data] => :error
    end
  end

  before_save do |retriever|
    if retriever.type == 'provider'
      retriever.bank_id = nil
    else
      retriever.provider_id = nil
    end
  end

  def provider?
    type == 'provider'
  end

  def bank?
    type == 'bank'
  end
end
