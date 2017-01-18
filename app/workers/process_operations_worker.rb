class ProcessOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_operations, retry: :false

  def perform
    $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))

    begin
      $lock.synchronize('process_operations', expiry: 10.minutes, retries: 1) do
        OperationService.process
      end
    rescue RemoteLock::Error
    end
  end
end
