# -*- encoding : UTF-8 -*-
class FiduceoProviderWishMailer < ActionMailer::Base
  default from: 'notification@idocus.com'

  def notify(user, accepted, rejected, processing)
    @user       = user
    @accepted   = accepted
    @rejected   = rejected
    @processing = processing
    mail(to: @user.email, subject: '[iDocus] Traitement de vos demandes de nouveaux automates de récupération')
  end
end
