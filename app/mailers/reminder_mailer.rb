# -*- encoding : UTF-8 -*-
class ReminderMailer < ActionMailer::Base
  default from: 'notification@idocus.com', reply_to: 'support@idocus.com'

  def remind mail, user
    @content = mail.content
    mail(to: user.email, subject: mail.subject)
  end
end
