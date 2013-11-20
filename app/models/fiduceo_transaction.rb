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
                        'BROKER_UNAVAILABLE'
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
                      'BROKER_UNAVAILABLE'
                   ]

  field :fiduceo_id
  field :status,                                default: 'PENDING'
  field :events,                 type: Hash
  field :retrieved_document_ids, type: Array,   default: []
  field :is_processed,           type: Boolean, default: false

  belongs_to :user
  belongs_to :retriever,      class_name: 'FiduceoRetriever', inverse_of: 'transactions'
  has_many   :temp_documents

  scope :processed,     where: { :status.in => FINISHED_STATUSES }
  scope :not_processed, any_of({ :status.in => NOT_FINISHED_STATUSES }, { :retrieved_document_ids.nin => [], is_processed: false })

  def processing?
    status.in? NOT_FINISHED_STATUSES
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
end
