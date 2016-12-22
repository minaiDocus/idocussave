class DeliverToGroupingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :grouping_delivery, retry: :false, unique: :until_and_while_executing


  def perform(temp_document_id)
    AccountingWorkflow::SendToGrouping.new(TempDocument.find(temp_document_id)).execute
  end
end
