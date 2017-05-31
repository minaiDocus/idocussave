class ScansNotDeliveredNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    ScanService.notify_not_delivered
  end
end
