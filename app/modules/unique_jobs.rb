# Used with sidekiq to create unique jobs, works accross workers
module UniqueJobs
  def self.for(name, expiry=1.day, retries=1)
    begin
      $remote_lock.synchronize(name, expiry: expiry, retries: retries) do
        yield
      end
    rescue RemoteLock::Error
    end
  end
end
