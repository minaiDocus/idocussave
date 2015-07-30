# -*- encoding : UTF-8 -*-
class ReminderMailer < ActionMailer::Base
  def remind mail, user
    @content = mail.content
    @content.gsub!(/#{Regexp.quote('[[nom du client]]')}/i, user.last_name)
    @content.gsub!(/#{Regexp.quote('[[nom du cabinet]]')}/i, user.organization.name)
    @content.gsub!(/#{Regexp.quote('[[mail aministrateur du cabinet]]')}/i, "<a href='mailto:#{user.organization.leader.email}'>#{user.organization.leader.email}</a>")
    mail(to: user.email, subject: mail.subject)
  end
end
