# -*- encoding : UTF-8 -*-
class UserMailer < ActionMailer::Base
  default :from => "do-not-reply@idocus.com"

  def welcome(user)
    @user = user
    @url = SITE_INNER_URL + "/users/sign_in"
    mail(:to => user.email, :subject => "Bienvenue sur le site www.idocus.com")
  end
end
