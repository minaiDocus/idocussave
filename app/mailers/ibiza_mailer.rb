# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  def notify_deliveries(deliveries, addresses)
    @deliveries = deliveries

    @deliveries.each do |delivery|
      attachments["#{delivery.number}.xml"] = delivery.xml_data if delivery.xml_data.present?
    end

    to = addresses.first
    cc = addresses[1..-1] || []
    
    mail(to: to, cc: cc, subject: "[iDocus] Import d'écriture")
  end
end
