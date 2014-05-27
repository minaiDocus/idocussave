# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(email,subject="",content="")
    @content = content
    mail(:to => email, :subject => subject)
  end

  def new_bank_accounts(email, user, bank_accounts)
    @user = user
    @bank_accounts = bank_accounts
    mail(:to => email, :subject => "iDocus - compte bancaire paramètré par votre client #{@user.company}")
  end
end
