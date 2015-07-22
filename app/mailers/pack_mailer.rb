# -*- encoding : UTF-8 -*-
class PackMailer < ActionMailer::Base
  def new_document_available(user, packs, time=(Time.now - 12.hours))
    @user  = user
    @url   = Settings.inner_url + '/account/documents'
    @packs = packs
    @time  = time
    mail(to: user.email, subject: '[iDocus] Mise à jour des documents')
  end
end
