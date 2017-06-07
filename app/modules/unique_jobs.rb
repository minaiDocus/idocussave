# Used with sidekiq to create unique jobs, works accross workers
module UniqueJobs
  def self.for(name, expiry=1.day, retries=1)
    result, error = nil
    begin
      $remote_lock.synchronize(name, expiry: expiry, retries: retries) do
        begin
          result = yield
        rescue RemoteLock::Error => e
          error = e
        end
      end
    rescue RemoteLock::Error
    end
    raise error if error
    result
  end
end
