# -*- encoding : UTF-8 -*-
class NewProviderRequestMailer < ActionMailer::Base
  def notify(user, accepted, rejected, processing)
    @user       = user
    @accepted   = accepted
    @rejected   = rejected
    @processing = processing

    mail(to: @user.email, subject: '[iDocus] Traitement de vos demandes de nouveaux automates de récupération')
  end
end
