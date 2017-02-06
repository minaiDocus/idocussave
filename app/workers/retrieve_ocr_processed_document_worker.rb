class RetrieveOcrProcessedDocumentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: :false, unique: :until_and_while_executing

  def perform
    $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))

    begin
      $lock.synchronize('ocr_processing', expiry: 5.minutes, retries: 1) do
        AccountingWorkflow::OcrProcessing.fetch
      end
    rescue RemoteLock::Error
    end
  end
end