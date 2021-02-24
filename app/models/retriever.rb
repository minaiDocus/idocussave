# -*- encoding : UTF-8 -*-
class Retriever < ApplicationRecord
  attr_accessor :confirm_dyn_params, :check_journal

  attr_encrypted :login, random_iv: true
  attr_encrypted :password, random_iv: true

  belongs_to :user
  belongs_to :journal, class_name: 'AccountBookType', optional: true
  belongs_to :connector, optional: true
  has_many   :temp_documents
  has_many   :bank_accounts
  has_many   :webhook_contents, class_name: 'Archive::WebhookContent'

  serialize :capabilities

  validates_presence_of :name
  validate :presence_of_journal

  validates_uniqueness_of :bridge_id, allow_nil: true, allow_blank: true

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

    before_transition any  => :ready do |retriever, transition|
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
      transition [:synchronizing, :failed, :paused] => :successful
    end

    event :pause do
      transition [:synchronizing, :successful, :failed] => :paused
    end

    event :destroy do
      transition any => :destroyed
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
    capabilities && capabilities.include?('document')
  end

  def bank?
    capabilities && capabilities.include?('bank')
  end

  def provider_and_bank?
    capabilities && provider? && bank?
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

  def update_state_with(connection={})
    prev_state   = self.state
    prev_message = self.error_message

    id_from_retrieved_data       = (connection.try(:[], 'id').to_i == self.budgea_id.to_i && connection['source'] == 'ProcessRetrievedData') ? self.budgea_id.to_i : 0
    id_from_retriever_controller = (connection.try(:[], 'id').to_i == self.id.to_i && connection['source'] == 'RetrieversController') ? self.id.to_i : 0

    return false if id_from_retrieved_data == 0 && id_from_retriever_controller == 0

    error_connection            = connection['error'].presence || connection['code'].presence
    connection_error_message    = connection['error_message'].presence || connection['message'].presence || connection['description']

    return false if error_connection.to_s.match(/Can[']t force synchronization/i) || connection_error_message.to_s.match(/Can[']t force synchronization/i)

    case error_connection
    when 'wrongpass'
      error_message = connection_error_message.presence || 'Mot de passe incorrect.'
      self.update(is_new_password_needed: true, error_message: error_message, budgea_error_message: error_connection)
      self.fail_budgea_connection

      Notifications::Retrievers.new(self).notify_wrong_pass if self.state != prev_state
    when 'additionalInformationNeeded'
      self.update({error_message: connection_error_message, budgea_error_message: nil})

      if connection['fields'].present?
        self.pause_budgea_connection

        Notifications::Retrievers.new(self).notify_info_needed if self.state != prev_state
      elsif self.budgea_connection_failed?
        self.success_budgea_connection
      end
    when 'actionNeeded'
      error_message = connection_error_message.presence || 'Veuillez confirmer les nouveaux termes et conditions.'
      self.update({error_message: error_message, budgea_error_message: error_connection})
      self.fail_budgea_connection

      Notifications::Retrievers.new(self).notify_action_needed if self.state != prev_state
    when 'websiteUnavailable'
      self.update({error_message: 'Site web indisponible.', budgea_error_message: error_connection})
      self.fail_budgea_connection

      Notifications::Retrievers.new(self).notify_website_unavailable if self.state != prev_state
    when 'SCARequired'
      begin
        description = connection.try(:[], 'fields').try(:[], "0").try(:[], "description")
      rescue
        description = connection.try(:[], 'fields').try(:[], 0).try(:[], "description")
      end

      if connection['fields'].present? && description.present?
        self.update({error_message: description, budgea_error_message: nil})

        self.pause_budgea_connection

        Notifications::Retrievers.new(self).notify_info_needed if self.state != prev_state
      else
        self.update({error_message: "Authentification forte requise (SCARequired).\n #{connection_error_message}", budgea_error_message: error_connection})

        self.fail_budgea_connection

        Notifications::Retrievers.new(self).notify_bug if self.state != prev_state
      end
    else
      if error_connection.present?
        error_message = connection_error_message || error_connection
        error_type    = 'decoupled'

        if error_connection == 'bug'
          error_message = 'Service indisponible.'
          error_type    = 'bug'
        elsif error_connection == 'webauthRequired'
          error_message = 'Authentification Web requise.'
          error_type    = 'webauthRequired'
        end

        self.update({error_message: error_message, budgea_error_message: error_type})
        self.fail_budgea_connection

        Notifications::Retrievers.new(self).notify_bug if self.state != prev_state
      else
        self.success_budgea_connection if id_from_retrieved_data > 0 || (id_from_retriever_controller > 0 && connection['success'] == "true")
      end
    end

    self.reload

    log_info = {
      subject: "[Retriever] state after update",
      name: "UpdateRetrieverState",
      error_group: "[update-retriever-state] state after update",
      erreur_type: "update retriever state - state after update",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        retriever_id: self.id,
        retriever_name: self.service_name,
        user_code: self.user.code,
        state: self.state,
        error_message: self.error_message,
        previous_state: prev_state,
        previous_mess: prev_message,
        source: connection['source'],
        connection: connection.to_json
      }
    }

    ErrorScriptMailer.error_notification(log_info).deliver if connection['source'] == 'ProcessRetrievedData' && self.state != prev_state
  end

  def resume_me(force=false)
    token = self.user.budgea_account.try(:access_token)
    return "Can't be resume - token is nil" unless token

    client = Budgea::Client.new token
    client.resume_connexion(self, force)
  end

private

  def presence_of_journal
    if check_journal && (provider? || provider_and_bank?)
      errors.add(:journal, :blank) unless journal_id
    end
  end
end
