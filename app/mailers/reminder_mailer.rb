# -*- encoding : UTF-8 -*-
class ReminderMailer < ActionMailer::Base
  default reply_to: nil

  def remind(mail, user)
    @content = mail.content
    @content.gsub!(/#{Regexp.quote('[[nom du client]]')}/i, user.name)
    @content.gsub!(/#{Regexp.quote('[[nom du cabinet]]')}/i, user.organization.name)

    mail(to: user.email, subject: mail.subject)
  end
end
