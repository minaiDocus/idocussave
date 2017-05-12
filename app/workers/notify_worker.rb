class NotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: :false

  def perform(notification_id)
    notification = Notification.find notification_id
    NotificationsMailer.notify(notification).deliver
    notification.update is_sent: true
  end
end
