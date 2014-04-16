# -*- encoding : UTF-8 -*-
class FiduceoProviderWishMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(user, accepted, rejected)
    @user     = user
    @accepted = accepted
    @rejected = rejected
    mail(to: @user.email, subject: 'Traitement des demandes de nouveaux récupérateurs automatiques')
  end
end
