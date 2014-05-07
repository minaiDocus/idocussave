# -*- encoding : UTF-8 -*-
class FiduceoProviderWishMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(user, accepted, rejected, processing)
    @user       = user
    @accepted   = accepted
    @rejected   = rejected
    @processing = processing
    mail(to: @user.email, subject: 'Traitement de vos demandes de nouveaux automates de récupération')
  end
end
