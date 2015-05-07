# -*- encoding : UTF-8 -*-
class WelcomeMailer < ActionMailer::Base
  default from: 'notification@idocus.com', reply_to: 'support@idocus.com'

  def welcome_customer(user, encrypted_token)
    @user = user
    @encrypted_token = encrypted_token
    mail(to: @user.email, subject: '[iDocus] Création de compte iDocus')
  end

  def welcome_collaborator(collaborator, encrypted_token)
    @collaborator = collaborator
    @encrypted_token = encrypted_token
    mail(to: @collaborator.email, subject: '[iDocus] Création de compte iDocus')
  end
end
