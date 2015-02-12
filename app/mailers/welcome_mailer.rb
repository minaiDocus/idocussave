# -*- encoding : UTF-8 -*-
class WelcomeMailer < ActionMailer::Base
  default from: 'notification@idocus.com'

  def welcome_customer(user)
    @user = user
    mail(to: @user.email, subject: '[iDocus] Création de compte iDocus')
  end

  def welcome_collaborator(collaborator)
    @collaborator = collaborator
    mail(to: @collaborator.email, subject: '[iDocus] Création de compte iDocus')
  end
end
