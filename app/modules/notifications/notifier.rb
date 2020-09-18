# -*- encoding: UTF-8 -*-

class Notifications::Notifier
  def initialize(arguments={})
    @arguments = arguments
  end

  def self.notify(notification)
    NotificationsMailer.notify(notification).deliver

    #sending push notification to FCM
    Notifications::Firebase.new({ notification: notification }).send_firebase_notification

    notification.update is_sent: true
  end

  def create_notification(arguments)
    notification             = Notification.new
    notification.user        = arguments[:user]
    notification.notice_type = arguments[:notice_type]
    notification.title       = arguments[:title]
    notification.message     = arguments[:message]
    notification.url         = arguments[:url]
    notification.save

    notification
  end

  def send_notification(url, user, notice_type, title, message)
    notification = create_notification({
      url:         url,
      user:        user,
      notice_type: notice_type,
      title:       title,
      message:     message
    })

    Notifications::Notifier.delay.notify(notification)
  end
end