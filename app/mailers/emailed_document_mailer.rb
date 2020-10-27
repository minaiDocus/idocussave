class EmailedDocumentMailer < ActionMailer::Base
  def notify_success(email, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = Billing::Period.new user: emailed_document.user, current_time: Time.now.beginning_of_month

    mail(to: email.from, subject: "[iDocus] Envoi par mail (#{email.subject}) : succès", references: ["<#{email.message_id}>"])
  end

  def notify_finished_with_failure(email, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = Billing::Period.new user: emailed_document.user, current_time: Time.now.beginning_of_month

    mail(to: email.from, subject: "[iDocus] Envoi par mail (#{email.subject}) : terminé avec erreur", references: ["<#{email.message_id}>"])
  end

  def notify_failure(email, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = Billing::Period.new user: emailed_document.user, current_time: Time.now.beginning_of_month

    mail(to: email.from, subject: "[iDocus] Envoi par mail (#{email.subject}) : échec", references: ["<#{email.message_id}>"])
  end

  def notify_error(email, attachment_names)
    @user             = email.to_user
    @attachment_names = attachment_names
    @journals         = @user.account_book_types
    @period_service   = Billing::Period.new user: @user, current_time: Time.now.beginning_of_month

    mail(to: email.from, subject: "[iDocus] Envoi par mail (#{email.subject}) : erreur", references: ["<#{email.message_id}>"])
  end
end
