# -*- encoding : UTF-8 -*-
class WelcomeMailer < ActionMailer::Base
  def welcome_customer(user, token)
    @user   = user
    @token = token

    mail(to: @user.email, subject: '[iDocus] Création de compte iDocus')
  end

  def welcome_collaborator(collaborator, token)
    @token = token
    @collaborator = collaborator

    mail(to: @collaborator.email, subject: '[iDocus] Création de compte iDocus')
  end

  def welcome_guest_collaborator(guest, token)
    @token = token
    @guest = guest

    mail(to: @guest.email, subject: '[iDocus] Création de compte iDocus')
  end
end
