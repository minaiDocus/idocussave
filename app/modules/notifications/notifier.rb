# -*- encoding: UTF-8 -*-

class Notifications::Notifier
  def initialize(arguments={})
    @arguments = arguments
  end

  def self.notify(notification)
    NotificationsMailer.notify(notification).deliver

    #sending push notification to FCM
    # TEMP : Disable sending FCM until new mobile version is released
    # Notifications::Firebase.new({ notification: notification }).send_firebase_notification

    notification.update is_sent: true
  end

  def create_notification(arguments, send_notification = false)
    notification             = Notification.new
    notification.user        = arguments[:user]
    notification.notice_type = arguments[:notice_type]
    notification.title       = arguments[:title]
    notification.message     = arguments[:message]
    notification.url         = arguments[:url]
    notification.save

    sent = Notifications::Notifier.delay.notify(notification) if send_notification

    { is_sent: (sent || false), notification: notification }
  end
end