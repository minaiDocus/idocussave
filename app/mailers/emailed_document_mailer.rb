# -*- encoding : UTF-8 -*-
class EmailedDocumentMailer < ActionMailer::Base
  helper :application
  default from: 'do-not-reply@idocus.com'

  def notify_success(email, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = PeriodService.new user: emailed_document.user, current_time: Time.now.beginning_of_month
    mail(to: email, subject: '[iDocus - envoi par mail] : succès')
  end

  def notify_failure(email, emailed_document)
    @emailed_document = emailed_document
    @journals         = emailed_document.user.account_book_types
    @period_service   = PeriodService.new user: emailed_document.user, current_time: Time.now.beginning_of_month
    mail(to: email, subject: '[iDocus - envoi par mail] : échec')
  end

  def notify_error(email, user, attachment_names)
    @user             = user
    @attachment_names = attachment_names
    @journals         = user.account_book_types
    @period_service   = PeriodService.new user: user, current_time: Time.now.beginning_of_month
    mail(to: email, subject: '[iDocus - envoi par mail] : erreur')
  end
end
