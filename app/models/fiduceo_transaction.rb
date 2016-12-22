# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoTransaction < ActiveRecord::Base
  serialize :events, Hash
  serialize :wait_for_user_labels
  serialize :retrieved_document_ids


  NOT_FINISHED_STATUSES = %w(
    PENDING
    SCHEDULED
    IN_PROGRESS
    WAIT_FOR_USER_ACTION).freeze

  FINISHED_STATUSES = %w(
    COMPLETED
    COMPLETED_NOTHING_TO_DOWNLOAD
    COMPLETED_NOTHING_NEW_TO_DOWNLOAD
    COMPLETED_WITH_MISSING_DOCS
    COMPLETED_WITH_ERRORS
    LOGIN_FAILED
    UNEXPECTED_ACCOUNT_DATA
    CHECK_ACCOUNT
    DEMATERIALISATION_NEEDED
    RETRIEVER_ERROR
    PROVIDER_UNAVAILABLE
    TIMEOUT
    BROKER_UNAVAILABLE
    REJECTED).freeze

  SUCCESS_STATUSES = %w(
    COMPLETED
    COMPLETED_NOTHING_TO_DOWNLOAD
    COMPLETED_NOTHING_NEW_TO_DOWNLOAD).freeze

  ERROR_STATUSES = %w(
    COMPLETED_WITH_MISSING_DOCS
    COMPLETED_WITH_ERRORS
    LOGIN_FAILED
    UNEXPECTED_ACCOUNT_DATA
    CHECK_ACCOUNT
    DEMATERIALISATION_NEEDED
    RETRIEVER_ERROR
    PROVIDER_UNAVAILABLE
    TIMEOUT
    BROKER_UNAVAILABLE
    REJECTED).freeze

  self.inheritance_column = :_type_disabled

  belongs_to :user
  belongs_to :retriever, class_name: 'FiduceoRetriever', inverse_of: 'transactions'


  scope :processed,     -> { where(status: FINISHED_STATUSES) }
  scope :not_processed, -> { where(status: NOT_FINISHED_STATUSES) }


  def self.search_for_collection_with_options(collection, options)
    collection = collection.where(type:          options[:type])               if options[:type]
    collection = collection.where(status:       options[:status].upcase) if options[:status]
    collection = collection.where('custom_service_name LIKE ?', "%#{options[:custom_service_name]}%") if options[:custom_service_name]

    if options[:created_at]
      options[:created_at].each do |operator, value|
        collection = collection.where("created_at #{operator} '#{value}'")
      end
    end

    collection
  end


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


  def acceptable?
    status.in? %w(COMPLETED_WITH_MISSING_DOCS COMPLETED_WITH_ERRORS)
  end


  def critical_error?
    error? && status.in?(%w(RETRIEVER_ERROR BROKER_UNAVAILABLE))
  end
end
