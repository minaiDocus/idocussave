class Notifications::ScansNotDeliveredNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'ScansNotDeliveredNotification' do
      Notifications::ScanService.notify_not_delivered
    end
  end
end
