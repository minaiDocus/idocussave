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

  def notify_insane_retrievers(addresses)
    @insane_retrievers = FiduceoRetriever.insane
    @insane_retrievers = @insane_retrievers.sort_by { |retriever| [retriever.user.code, retriever.type, retriever.service_name] }
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: '[iDocus] Erreur récupérateur fiduceo - INSANE')
  end
end
