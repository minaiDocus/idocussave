# -*- encoding : UTF-8 -*-
class FiduceoTransaction
  include Mongoid::Document
  include Mongoid::Timestamps

  NOT_FINISHED_STATUSES = [
                            'PENDING',
                            'SCHEDULED',
                            'IN_PROGRESS',
                            'WAIT_FOR_USER_ACTION'
                          ]

  FINISHED_STATUSES = [
                        'COMPLETED',
                        'COMPLETED_NOTHING_TO_DOWNLOAD',
                        'COMPLETED_NOTHING_NEW_TO_DOWNLOAD',
                        'COMPLETED_WITH_MISSING_DOCS',
                        'COMPLETED_WITH_ERRORS',
                        'LOGIN_FAILED',
                        'UNEXPECTED_ACCOUNT_DATA',
                        'CHECK_ACCOUNT',
                        'DEMATERIALISATION_NEEDED',
                        'RETRIEVER_ERROR',
                        'PROVIDER_UNAVAILABLE',
                        'TIMEOUT',
                        'BROKER_UNAVAILABLE',
                        'REJECTED'
                      ]

  SUCCESS_STATUSES = [
                       'COMPLETED',
                       'COMPLETED_NOTHING_TO_DOWNLOAD',
                       'COMPLETED_NOTHING_NEW_TO_DOWNLOAD'
                     ]

  ERROR_STATUSES = [
                      'COMPLETED_WITH_MISSING_DOCS',
                      'COMPLETED_WITH_ERRORS',
                      'LOGIN_FAILED',
                      'UNEXPECTED_ACCOUNT_DATA',
                      'CHECK_ACCOUNT',
                      'DEMATERIALISATION_NEEDED',
                      'RETRIEVER_ERROR',
                      'PROVIDER_UNAVAILABLE',
                      'TIMEOUT',
                      'BROKER_UNAVAILABLE',
                      'REJECTED'
                   ]

  field :fiduceo_id
  field :status,                                default: 'PENDING'
  field :events,                 type: Hash
  field :wait_for_user_labels,   type: Array,   default: []
  field :retrieved_document_ids, type: Array,   default: []
  field :is_processed,           type: Boolean, default: false
  field :type,                                  default: 'provider'
  field :service_name
  field :custom_service_name

  belongs_to :user
  belongs_to :retriever,      class_name: 'FiduceoRetriever', inverse_of: 'transactions'

  scope :processed,     where: { :status.in => FINISHED_STATUSES }
  scope :not_processed, where: { :status.in => NOT_FINISHED_STATUSES }

  def processing?
    status.in? NOT_FINISHED_STATUSES
  end

  def wait_for_user_action?
    status == 'WAIT_FOR_USER_ACTION'
  end

  def finished?
    status.in? FINISHED_STATUSES
  end

  def success?
    status.in? SUCCESS_STATUSES
  end

  def error?
    status.in? ERROR_STATUSES
  end

  def retryable?
    error? && !status.in?(%w(LOGIN_FAILED UNEXPECTED_ACCOUNT_DATA))
  end

  def not_retryable?
    !retryable?
  end

  def critical_error?
    error? && status.in?(%w(RETRIEVER_ERROR BROKER_UNAVAILABLE))
  end
end
