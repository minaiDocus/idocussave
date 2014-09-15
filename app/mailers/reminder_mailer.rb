# -*- encoding : UTF-8 -*-
class ReminderMailer < ActionMailer::Base
  helper :application
  default from: 'do-not-reply@idocus.com'

  def remind mail, user
    @content = mail.content
    mail(to: user.email, subject: mail.subject)
  end
end
