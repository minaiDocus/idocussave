# -*- encoding : UTF-8 -*-
class PackMailer < ActionMailer::Base
  default from: 'do-not-reply@idocus.com'

  def new_document_available(user, packs, time=(Time.now - 12.hours))
    @user  = user
    @url   = SITE_INNER_URL + '/account/documents'
    @packs = packs
    @time  = time
    mail(to: user.email, subject: 'Mise à jour des documents')
  end
end
