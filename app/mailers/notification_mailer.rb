# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(email,subject="",content="")
    @content = content
    mail(:to => email, :subject => subject)
  end
end
