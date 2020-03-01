class ScansNotDeliveredNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'ScansNotDeliveredNotification' do
      ScanService.notify_not_delivered
    end
  end
end
