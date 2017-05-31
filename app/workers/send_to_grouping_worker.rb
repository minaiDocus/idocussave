class SendToGroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(temp_document_id)
    UniqueJobs.for "SendToGrouping-#{temp_document_id}", 1.day, 2 do
      AccountingWorkflow::SendToGrouping.new(TempDocument.find(temp_document_id)).execute
    end
  end
end
