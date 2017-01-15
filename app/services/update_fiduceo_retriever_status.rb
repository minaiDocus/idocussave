# -*- encoding : UTF-8 -*-
class UpdateFiduceoRetrieverStatus
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

  class << self
    def execute(retriever_id, fetch_data=true)
      new(retriever_id, fetch_data).execute
    end
    # TODO change with sidekiq worker system
    # handle_asynchronously :execute, priority: 2, run_at: Proc.new { 5.seconds.from_now }
  end

  def initialize(object, fetch_data=true)
    @retriever = if object.class == Retriever
      object
    else
      Retriever.find object
    end
    @fetch_data = fetch_data
  end

  def execute
    data = client.transaction @retriever.fiduceo_transaction_id
    if client.response.code == 200
      @status = data['transactionStatus']
      if @retriever.processing? || @status.in?(FINISHED_STATUSES)
        if @status == 'WAIT_FOR_USER_ACTION'
          if data['waitForUserLabel']
            @retriever.additionnal_fields = []
            data['waitForUserLabel'].split('||').each do |label|
              @retriever.additionnal_fields << { label: label, name: label }
            end
            @retriever.save
          end
          @retriever.pause_fiduceo_connection
        elsif @status.in? ERROR_STATUSES
          @retriever.fiduceo_error_message = @status
          @retriever.fail_fiduceo_connection
        elsif @status.in? SUCCESS_STATUSES
          @retriever.success_fiduceo_connection
        end
        if @fetch_data && (@status.in?(SUCCESS_STATUSES) || @status.in?(['COMPLETED_WITH_MISSING_DOCS', 'COMPLETED_WITH_ERRORS']))
          FetchFiduceoData.execute(@retriever)
        end
      end
      UpdateFiduceoRetrieverStatus.execute(@retriever, @fetch_data) unless @status.in?(FINISHED_STATUSES)
      true
    else
      raise Fiduceo::Errors::ServiceUnavailable.new('transaction')
    end
  end

private

  def client
    @client ||= Fiduceo::Client.new @retriever.user.fiduceo_id
  end
end
