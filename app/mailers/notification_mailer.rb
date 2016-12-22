# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  def notify(addresses, subject = '', content = '')
    @content = content

    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: subject)
  end


  def subscription_updated(addresses, collaborator, user, options)
    @user            = user
    @options       = options
    @collaborator = collaborator
    
    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: "[iDocus] Modification de l'abonnement du client : #{user}")
  end
end
