class NotifyPaperQuotaReachedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'NotifyPaperQuotaReachedWorker' do
      NotifyPaperQuotaReached.execute
    end
  end
end
