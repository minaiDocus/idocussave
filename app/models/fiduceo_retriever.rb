# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoRetriever < ActiveRecord::Base
  serialize :pending_document_ids


  attr_accessor :pass, :param1, :param2, :param3, :sparam1, :sparam2, :sparam3

  self.inheritance_column = :_type_disabled

  belongs_to :user
  belongs_to :journal,        class_name: 'AccountBookType',    inverse_of: 'fiduceo_retrievers'
  has_many   :transactions,   class_name: 'FiduceoTransaction', inverse_of: 'retriever', foreign_key: :retriever_id
  has_many   :temp_documents
  has_many   :bank_accounts, inverse_of: 'retriever', dependent: :destroy


  validates_presence_of :type, :name, :login, :service_name
  validates_inclusion_of :type, in: %w(provider bank)
  validates_presence_of :journal, if: :provider?
  validate :inclusion_of_frequency


  scope :providers,                     -> { where(type: 'provider') }
  scope :banks,                         -> { where(type: 'bank') }
  scope :active,                        -> { where(is_active: true) }
  scope :auto,                          -> { where(is_auto: true) }
  scope :manual,                        -> { where(is_auto: false) }
  scope :every_day,                     -> { where(frequency: 'day') }
  scope :password_renewal_not_notified, -> { where(is_password_renewal_notified: false) }

  scope :scheduled,            -> { where(state: 'scheduled', is_active: true) }
  scope :insane,               -> { where(state: 'scheduled', is_active: true, is_sane: false) }
  scope :processing,           -> { where(state: 'processing') }
  scope :wait_selection,       -> { where(state: 'wait_selection') }
  scope :wait_for_user_action, -> { where(state: 'wait_for_user_action') }
  scope :error,                -> { where(state: 'error') }
  scope :not_processed,        -> { where(state: %w(processing wait_for_user_action)) }



  state_machine initial: :scheduled do
    state :ready
    state :scheduled
    state :processing
    state :wait_selection
    state :wait_for_user_action
    state :error

    after_transition any => :scheduled do |retriever, _transition|
      transaction = retriever.transactions.order(created_at: :asc).last
      if transaction && transaction.wait_for_user_labels.any?
        retriever.update_attribute(:is_auto, false) if retriever.is_auto
        retriever.ready
      else
        retriever.update_attribute(:is_auto, true) unless retriever.is_auto
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
      transition processing: :wait_selection
    end

    event :wait_for_user_action do
      transition processing: :wait_for_user_action
    end

    event :error do
      transition [:processing, :wait_for_user_action] => :error
    end
  end


  before_create :initialize_serialized_attributes

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


  def self.search(contains)
    retrievers = FiduceoRetriever.all

    user_ids = []

    if contains[:user_code].present?
      user_ids = User.where("code LIKE ?", "%#{params[:retriever_contains][:user_code]}%").pluck(:id)
    end

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        retrievers = retrievers.where("created_at #{operator} '#{value}'")
      end
    end

    if contains[:updated_at]
      contains[:updated_at].each do |operator, value|
        retrievers = retrievers.where("updated_at #{operator} '#{value}'")
      end
    end

    retrievers = retrievers.where(type:           contains[:type])         if contains[:type].present?
    retrievers = retrievers.where("name LIKE ?",  "%#{contains[:name]}%")  if contains[:name].present?
    retrievers = retrievers.where("state LIKE ?", "%#{contains[:state]}%") if contains[:state].present?
    retrievers = retrievers.where(user_id:        user_ids)                if user_ids.any?
    retrievers = retrievers.where(is_sane:        contains[:is_sane])      if contains[:is_sane].present?
    retrievers = retrievers.where("service_name LIKE ?",       "%#{contains[:service_name]}%")       if contains[:service_name].present?
    retrievers = retrievers.where("transaction_status LIKE ?", "%#{contains[:transaction_status]}%") if contains[:transaction_status].present?

    retrievers
  end


  def self.search_for_collection(collection, contains)
    collection = collection.where('name LIKE ?', "%#{contains[:name]}%") unless contains[:name].blank?

    collection
  end


  private


  def inclusion_of_frequency
    unless (frequency.split('-') - %w(day mon tue wed thu fri sat sun)).empty?
      errors.add(:frequency, :inclusion)
    end
  end


  def initialize_serialized_attributes
    self.pending_document_ids ||= []
  end
end
