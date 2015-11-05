# -*- encoding : UTF-8 -*-
class PackMailer < ActionMailer::Base
  def new_document_available(user, packs, start_at, end_at)
    @user     = user
    @url      = Settings.inner_url + '/account/documents'
    @packs    = packs
    @start_at = start_at
    @end_at   = end_at
    mail(to: user.email, subject: '[iDocus] Mise à jour des documents')
  end
end
