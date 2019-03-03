# -*- encoding : UTF-8 -*-
class Retriever < ApplicationRecord
  attr_accessor :confirm_dyn_params, :check_journal

  belongs_to :user
  belongs_to :journal,               class_name: 'AccountBookType'
  has_many   :temp_documents
  has_many   :bank_accounts

  serialize :capabilities

  validates_presence_of :name
  validate :presence_of_journal

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
      retriever.configure_budgea_connection if retriever.try(:budgea_connector_id)
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
  scope :linked,                   -> { where('budgea_id IS NOT NULL AND budgea_id != ""') }

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

    after_transition any => [:configuring, :running, :destroying] do |retriever, transition|
      retriever.synchronize_budgea_connection  if retriever.try(:budgea_connector_id)
    end

    event :ready do
      transition [:configuring, :running, :waiting_selection, :waiting_additionnal_info, :error] => :ready
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
      transition [:ready, :configuring, :destroying, :waiting_additionnal_info, :running, :error] => :error
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
      retriever.ready
    end

    after_transition any => :failed do |retriever, transition|
      retriever.error_message = retriever.budgea_error_message
      retriever.error
    end

    after_transition any => :destroyed do |retriever, transition|
      retriever.destroy
    end

    after_transition any => :paused do |retriever, transition|
      retriever.wait_additionnal_info
    end

    event :configure do
      transition :not_configured => :synchronizing
    end

    event :synchronize do
      transition [:successful, :failed, :paused] => :synchronizing
    end

    event :fail do
      transition [:synchronizing, :paused, :successful, :failed] => :failed
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

  def uniq?
    self.user.retrievers.where(budgea_id: self.budgea_id).count == 1
  end

  def not_uniq?
    not uniq?
  end

  def linked?
    budgea_id.present?
  end

private

  def presence_of_journal
    if check_journal && (provider? || provider_and_bank?)
      errors.add(:journal, :blank) unless journal_id
    end
  end
end
