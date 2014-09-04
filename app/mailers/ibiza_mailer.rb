# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify_delivery(ibiza, object, xml_data=nil)
    @ibiza  = ibiza
    if object.class == Pack::Report
      @report = object
    else
      @preseizure = object
      @report     = @preseizure.report
    end
    attachments['entries.xml'] = xml_data if xml_data.present?
    mail(to: IbizaAPI::Config::NOTIFY_TO, cc: EventNotification::EMAILS, subject: "iDocus - Import d'écriture")
  end
end
