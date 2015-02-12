# -*- encoding : UTF-8 -*-
class FiduceoRetrieverMailer < ActionMailer::Base
  default from: 'notification@idocus.com'

  def notify_password_renewal(user)
    @user = user
    mail(to: @user.email, subject: '[iDocus] Automate bloqué pour cause de mot de passe obsolète')
  end
end
