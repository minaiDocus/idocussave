# -*- encoding : UTF-8 -*-
class PackMailer < ActionMailer::Base
  def new_document_available(user, packs, start_at, end_at)
    @url   = Settings.inner_url + '/account/documents'
    @user = user
    @packs   = packs
    @end_at  = end_at
    @start_at = start_at
    
    mail(to: user.email, subject: '[iDocus] Mise à jour des documents')
  end
end
