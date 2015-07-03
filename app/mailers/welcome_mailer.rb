# -*- encoding : UTF-8 -*-
class WelcomeMailer < ActionMailer::Base
  default from: 'notification@idocus.com', reply_to: 'support@idocus.com'

  def welcome_customer(user, token)
    @user = user
    @token = token
    mail(to: @user.email, subject: '[iDocus] Création de compte iDocus')
  end

  def welcome_collaborator(collaborator, token)
    @collaborator = collaborator
    @token = token
    mail(to: @collaborator.email, subject: '[iDocus] Création de compte iDocus')
  end
end
