class ProcessOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :process_operations, retry: :false, unique: :until_and_while_executing

  def perform
    $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))

    begin
      $lock.synchronize('process_operations', expiry: 2.days.from_now, retries: 1) do
        ProcessOperation.execute unless JobsOrchestrator.check_if_in_queue('ProcessOperationsWorker')
      end
    rescue RemoteLock::Error
    end
  end
end
