class JobProcessorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'JobProcessorWorker' do
      JobProcessorService.execute
    end
  end
end