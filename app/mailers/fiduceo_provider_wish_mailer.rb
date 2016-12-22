# -*- encoding : UTF-8 -*-
class FiduceoProviderWishMailer < ActionMailer::Base
  def notify(user, accepted, rejected, processing)
    @user          = user
    @rejected     = rejected
    @accepted   = accepted
    @processing = processing
    
    mail(to: @user.email, subject: '[iDocus] Traitement de vos demandes de nouveaux automates de récupération')
  end
end
