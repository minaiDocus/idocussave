class SendToGroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(temp_document_id)
    UniqueJobs.for "SendToGrouping-#{temp_document_id}", 1.day, 2 do
      temp_document = TempDocument.find(temp_document_id)
      AccountingWorkflow::SendToGrouping.new(temp_document).execute if temp_document.bundle_needed?
    end
  end
end
