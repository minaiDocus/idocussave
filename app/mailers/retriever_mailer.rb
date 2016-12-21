# -*- encoding : UTF-8 -*-
class RetrieverMailer < ActionMailer::Base
  def notify_password_renewal(user)
    @user = user
    mail(to: @user.email, subject: '[iDocus] Automate bloqué pour cause de mot de passe obsolète')
  end

  def notify_insane_retrievers(addresses)
    @insane_retrievers = Retriever.insane
    @insane_retrievers = @insane_retrievers.sort_by { |retriever| [retriever.user.code, retriever.capabilities.join('_'), retriever.service_name] }
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: '[iDocus] Erreur récupérateur - INSANE')
  end
end
