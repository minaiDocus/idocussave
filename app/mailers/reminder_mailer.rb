# -*- encoding : UTF-8 -*-
class ReminderMailer < ActionMailer::Base
  def remind mail, user
    @content = mail.content
    mail(to: user.email, subject: mail.subject)
  end
end
