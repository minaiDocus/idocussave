# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  helper :application
  default from: 'notification@idocus.com'

  def notify_delivery(addresses, ibiza, object, xml_data=nil)
    @ibiza  = ibiza
    if object.class == Pack::Report
      @report = object
    else
      @preseizure = object
      @report     = @preseizure.report
    end
    attachments['entries.xml'] = xml_data if xml_data.present?
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: "iDocus - Import d'écriture")
  end
end
