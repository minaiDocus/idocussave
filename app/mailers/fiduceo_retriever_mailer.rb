# -*- encoding : UTF-8 -*-
class FiduceoRetrieverMailer < ActionMailer::Base
  def notify_transaction_error(addresses, transaction)
    to = addresses.first
    cc = addresses[1..-1] || []
    @transaction = transaction
    mail(to: to, cc: cc, subject: "[iDocus] Erreur transaction fiduceo - #{@transaction.status}")
  end

  def notify_password_renewal(user)
    @user = user
    mail(to: @user.email, subject: '[iDocus] Automate bloqué pour cause de mot de passe obsolète')
  end
end
