class CheckWriteDiskWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'CheckWriteDiskWorker' do
      CheckWriteDiskService.execute
    end
  end
end