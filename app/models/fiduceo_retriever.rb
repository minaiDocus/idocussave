# -*- encoding : UTF-8 -*-
class FiduceoRetriever
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :pass, :param1, :param2, :param3

  belongs_to :user
  belongs_to :journal,        class_name: 'AccountBookType',    inverse_of: 'fiduceo_retrievers'
  has_many   :transactions,   class_name: 'FiduceoTransaction', inverse_of: 'retriever',          dependent: :destroy
  has_many   :temp_documents

  field :fiduceo_id
  field :provider_id
  field :bank_id
  field :type,                               default: 'provider'
  field :name
  field :login
  field :state
  field :is_active,           type: Boolean, default: true
  field :is_documents_locked, type: Boolean, default: true

  validates_presence_of :type, :name, :login
  validates_inclusion_of :type, in: %w(provider bank)

  scope :providers, where: { type: 'provider' }
  scope :banks,     where: { type: 'bank' }
  scope :active,    where: { is_active: true }

  state_machine initial: :scheduled do
    state :scheduled
    state :processing
    state :wait_user_action
    state :error

    event :schedule do
      transition [:processing, :wait_user_action, :error] => :scheduled
    end

    event :fetch do
      transition :scheduled => :processing
    end

    event :wait_user_action do
      transition :processing => :wait_user_action
    end

    event :error do
      transition :processing => :error
    end
  end

  scope :scheduled,  where: { state: 'scheduled', is_active: true }
  scope :processing, where: { state: 'processing' }
  scope :error,      where: { state: 'error' }
end
