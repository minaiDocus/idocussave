class NotificationsMailer < ActionMailer::Base
  def notify(notification)
    @notification = notification

    mail(to: @notification.user.email, subject: '[iDocus] ' + t("notifications.#{notification.notice_type}.title"))
  end
end
