class ProcessAndDeliverGroupedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_and_deliver_grouped, retry: :false, unique: :until_and_while_executing

  def perform(temp_pack_id)
    begin
      $remote_lock.synchronize("TempPackProcessor-#{temp_pack_id}", expiry: 6.hours, retries: 1) do
        AccountingWorkflow::TempPackProcessor.process(TempPack.find(temp_pack_id))
      end
    rescue RemoteLock::Error
    end
  end
end
