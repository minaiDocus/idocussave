# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  helper :application
  default from: 'do-not-reply@idocus.com'

  def notify_error(ibiza, report, xml_data=nil)
    @ibiza = ibiza
    @report = report
    attachments['entries.xml'] = xml_data if xml_data.present?
    mail(to: IbizaAPI::Config::NOTIFY_ERROR_TO, cc: ErrorNotification::EMAILS, subject: "iDocus - erreur d'import")
  end
end
