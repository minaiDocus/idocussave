# -*- encoding : UTF-8 -*-
class EmailedDocumentMailer < ActionMailer::Base
  def notify_success(email_address, email_message_id, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = PeriodService.new user: emailed_document.user, current_time: Time.now.beginning_of_month
    mail(to: email_address, subject: '[iDocus] Envoi par mail : succès', references: ["<#{email_message_id}>"])
  end

  def notify_failure(email_address, email_message_id, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = PeriodService.new user: emailed_document.user, current_time: Time.now.beginning_of_month
    mail(to: email_address, subject: '[iDocus] Envoi par mail : échec', references: ["<#{email_message_id}>"])
  end

  def notify_error(email_address, email_message_id, user, attachment_names)
    @user             = user
    @attachment_names = attachment_names
    @journals         = user.account_book_types
    @period_service   = PeriodService.new user: user, current_time: Time.now.beginning_of_month
    mail(to: email_address, subject: '[iDocus] Envoi par mail : erreur', references: ["<#{email_message_id}>"])
  end
end
