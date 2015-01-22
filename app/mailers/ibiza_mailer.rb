# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  helper :application
  default from: 'notification@idocus.com'

  def notify_delivery(delivery, addresses, ibiza, object)
    @delivery = delivery
    @ibiza  = ibiza
    if object.class == Pack::Report
      @report = object
    else
      @preseizure = object
      @report     = @preseizure.report
    end
    attachments['entries.xml'] = @delivery.xml_data if @delivery.xml_data.present?
    to = addresses.first
    cc = addresses[1..-1] || []
    mail(to: to, cc: cc, subject: "iDocus - Import d'écriture")
  end
end
