class ProcessOperationsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'ProcessOperations', 2.days do
      ProcessOperation.execute
    end
  end
end
