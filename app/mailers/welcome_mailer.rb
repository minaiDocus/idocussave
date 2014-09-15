# -*- encoding : UTF-8 -*-
class WelcomeMailer < ActionMailer::Base
  helper :application
  default from: 'do-not-reply@idocus.com'

  def welcome_customer(user)
    @user = user
    mail(to: @user.email, subject: 'Création de compte iDocus')
  end

  def welcome_collaborator(collaborator)
    @collaborator = collaborator
    mail(to: @collaborator.email, subject: 'Création de compte iDocus')
  end
end
