class ProcessRetrievedDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    error = nil
    begin
      $remote_lock.synchronize('process_retrieved_data_task', expiry: 1.day, retries: 1) do
        begin
          ProcessRetrievedData.concurrently(1.minute)
        rescue => e
          error = e
        end
      end
    rescue RemoteLock::Error
    end
    raise error if error
    true
  end
end
