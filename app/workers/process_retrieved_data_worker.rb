class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrievers, retry: :false

  def perform
    $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))

    begin
      $lock.synchronize('synchronize_retriever_task', expiry: 15.minutes, retries: 1) do
        ProcessRetrievedData.concurrently(1.minute)
      end
    rescue RemoteLock::Error
    end
  end
end
