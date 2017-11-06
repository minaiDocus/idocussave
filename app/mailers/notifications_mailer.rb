class NotificationsMailer < ActionMailer::Base
  def notify(notification)
    @notification = notification
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    mail to: @notification.user.email, subject: '[iDocus] ' + @notification.title
  end

  def notify_retrievers_bug_to_admin(retriever)
    @retriever = retriever
    mail to: 'developpeurs@idocus.com', subject: '[iDocus] Automate - Bug'
  end
end
