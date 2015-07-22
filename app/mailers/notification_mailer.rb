# -*- encoding : UTF-8 -*-
class NotificationMailer < ActionMailer::Base
  def notify(addresses, subject='', content='')
    @content = content
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: subject)
  end

  def subscription_updated(addresses, collaborator, user, options)
    @collaborator = collaborator
    @user         = user
    @options      = options
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: "[iDocus] Modification de l'abonnement du client : #{user}")
  end

  def new_bank_accounts(collaborator, user, bank_accounts)
    @collaborator  = collaborator
    @user          = user
    @bank_accounts = bank_accounts
    mail(to: @collaborator.email, subject: "[iDocus] compte bancaire paramétré par votre client #{@user.company}")
  end
end
