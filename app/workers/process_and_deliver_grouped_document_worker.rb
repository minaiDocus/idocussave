class ProcessAndDeliverGroupedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_and_deliver_grouped, retry: :false, unique: :until_and_while_executing

  def perform(temp_pack_id)
    AccountingWorkflow::TempPackProcessor.process(TempPack.find(temp_pack_id))
  end
end
