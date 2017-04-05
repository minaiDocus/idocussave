class ScansNotDeliveredNotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: :false, unique: :until_and_while_executing

  def perform
    ScanService.notify_not_delivered
  end
end
