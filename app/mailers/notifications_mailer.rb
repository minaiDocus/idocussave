class NotificationsMailer < ActionMailer::Base
  def notify(notification)
    @notification = notification
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    mail to: @notification.user.email, subject: '[iDocus] ' + @notification.title
  end
end
