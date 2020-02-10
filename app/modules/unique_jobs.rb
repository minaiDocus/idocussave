# Used with sidekiq to create unique jobs, works accross workers
module UniqueJobs
  def self.for(name, expiry=1.day, retries=1)
    result, error = nil

    job_processing       = JobProcessing.where(name: name.to_s).not_killed.first.presence || JobProcessing.new
    job_processing.name  = name.to_s
    is_started           = false

    begin
      $remote_lock.synchronize(name, expiry: expiry, retries: retries) do
        is_started = true
        job_processing.start

        begin
          result = yield
        rescue RemoteLock::Error => e
          error = e
        end
      end
    rescue RemoteLock::Error
    end

    if error
      job_processing.notifications = error.to_s
      job_processing.save

      raise error
    else
      job_processing.finish if is_started
    end

    result
  end
end