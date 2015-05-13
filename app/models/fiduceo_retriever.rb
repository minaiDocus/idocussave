# -*- encoding : UTF-8 -*-
class FiduceoRetriever
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :pass, :param1, :param2, :param3, :sparam1, :sparam2, :sparam3

  belongs_to :user
  belongs_to :journal,        class_name: 'AccountBookType',    inverse_of: 'fiduceo_retrievers'
  has_many   :transactions,   class_name: 'FiduceoTransaction', inverse_of: 'retriever'
  has_many   :temp_documents
  has_many   :bank_accounts,                                    inverse_of: 'retriever',          dependent: :destroy

  field :fiduceo_id
  field :provider_id
  field :bank_id
  field :service_name
  field :type,                                        default: 'provider'
  field :name
  field :login
  field :state
  field :is_active,                    type: Boolean, default: true
  field :is_selection_needed,          type: Boolean, default: true
  field :is_auto,                      type: Boolean, default: true
  field :is_password_renewal_notified, type: Boolean, default: false
  field :wait_for_user,                type: Boolean, default: false
  field :wait_for_user_label
  field :pending_document_ids,         type: Array,   default: []
  field :frequency,                                   default: 'day'
  field :journal_name
  field :transaction_status

  validates_presence_of :type, :name, :login, :service_name
  validates_inclusion_of :type, in: %w(provider bank)
  validate :inclusion_of_frequency

  scope :providers,                     where(type: 'provider')
  scope :banks,                         where(type: 'bank')
  scope :active,                        where(is_active: true)
  scope :auto,                          where(is_auto: true)
  scope :manual,                        where(is_auto: false)
  scope :every_day,                     where(frequency: 'day')
  scope :password_renewal_not_notified, where(is_password_renewal_notified: false)

  state_machine initial: :scheduled do
    state :ready
    state :scheduled
    state :processing
    state :wait_selection
    state :wait_for_user_action
    state :error

    after_transition any => :scheduled do |retriever, transition|
      transaction = retriever.transactions.asc(:created_at).last
      if transaction && transaction.wait_for_user_labels.any?
        retriever.update_attribute(:is_auto, false) if retriever.is_auto
        retriever.ready
      else
        retriever.update_attribute(:is_auto, true) unless retriever.is_auto
      end
    end

    after_transition :processing => :scheduled do |retriever, transition|
      if retriever.bank? && retriever.bank_accounts.any?
        OperationService.delay(run_at: 3.minutes.from_now).fetch retriever
      end
    end

    event :schedule do
      transition [:ready, :processing, :wait_selection, :wait_for_user_action, :error] => :scheduled
    end

    event :ready do
      transition [:scheduled, :processing, :wait_selection, :wait_for_user_action, :error] => :ready
    end

    event :fetch do
      transition [:ready, :scheduled, :wait_for_user_action] => :processing
    end

    event :wait_selection do
      transition :processing => :wait_selection
    end

    event :wait_for_user_action do
      transition :processing => :wait_for_user_action
    end

    event :error do
      transition [:processing, :wait_for_user_action] => :error
    end
  end

  scope :scheduled,            where(state: 'scheduled', is_active: true)
  scope :processing,           where(state: 'processing')
  scope :wait_selection,       where(state: 'wait_selection')
  scope :wait_for_user_action, where(state: 'wait_for_user_action')
  scope :error,                where(state: 'error')
  scope :not_processed,        where(:state.in => %w(processing wait_for_user_action))

  before_save do |fiduceo_retriever|
    if fiduceo_retriever.type == 'provider'
      fiduceo_retriever.bank_id = nil
    else
      fiduceo_retriever.provider_id = nil
    end
  end

  def provider?
    type == 'provider'
  end

  def bank?
    type == 'bank'
  end

private

  def inclusion_of_frequency
    unless (frequency.split('-') - %w(day mon tue wed thu fri sat sun)).empty?
      errors.add(:frequency, :inclusion)
    end
  end
end
