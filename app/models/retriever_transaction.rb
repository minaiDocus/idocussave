# -*- encoding : UTF-8 -*-
class RetrieverTransaction
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

  field :api_id
  field :api_name
  field :status,                                default: 'PENDING'
  field :events,                 type: Hash
  field :wait_for_user_labels,   type: Array,   default: []
  field :retrieved_document_ids, type: Array,   default: []
  field :is_processed,           type: Boolean, default: false
  field :type,                                  default: 'provider'
  field :service_name
  field :custom_service_name

  belongs_to :user
  belongs_to :retriever

  scope :processed,     -> { where(:status.in => FINISHED_STATUSES) }
  scope :not_processed, -> { where(:status.in => NOT_FINISHED_STATUSES) }

  def success?
    status.in? SUCCESS_STATUSES
  end

  def error?
    status.in? ERROR_STATUSES
  end
end
