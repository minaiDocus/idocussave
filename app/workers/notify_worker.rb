class NotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: false

  def perform(notification_id)
    notification = Notification.find notification_id
    NotificationsMailer.notify(notification).deliver
    
    #sending push notification to FCM
    FirebaseNotification.send_notification(notification)
    
    notification.update is_sent: true
  end
end
