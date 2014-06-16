# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(email,subject="",content="")
    @content = content
    mail(:to => email, :subject => subject)
  end

  def new_bank_accounts(collaborator, user, bank_accounts)
    @collaborator  = collaborator
    @user          = user
    @bank_accounts = bank_accounts
    mail(:to => @collaborator.email, :subject => "iDocus - compte bancaire paramètré par votre client #{@user.company}")
  end
end
