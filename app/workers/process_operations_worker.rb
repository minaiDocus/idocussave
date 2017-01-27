class ProcessOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_operations, retry: :false

  def perform
    $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))

    begin
      $lock.synchronize('process_operations', expiry: 10.minutes, retries: 1) do
        ProcessOperation.execute
      end
    rescue RemoteLock::Error
    end
  end
end
