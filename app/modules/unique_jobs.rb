# Used with sidekiq to create unique jobs, works accross workers
module UniqueJobs
  def self.for(name, expiry)
    begin
      $remote_lock.synchronize(name, expiry: expiry, retries: 1) do
        yield
      end
    rescue RemoteLock::Error
    end
  end
end
