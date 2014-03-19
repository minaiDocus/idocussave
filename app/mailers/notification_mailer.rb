# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(email,subject="",content="")
    @content = content
    mail(:to => email, :subject => subject)
  end

  def new_bank_accounts(fiduceo_retriever, email)
    @fiduceo_retriever = fiduceo_retriever
    mail(:to => email, :subject => "iDocus - compte bancaire paramètré par votre client #{@fiduceo_retriever.user.company}")
  end
end
