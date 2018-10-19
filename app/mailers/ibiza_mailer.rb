# -*- encoding : UTF-8 -*-
class IbizaMailer < ActionMailer::Base
  def notify_deliveries(deliveries, addresses)
    @deliveries = deliveries

    @deliveries.each do |delivery|
      attachments["#{delivery.id}.xml"] = delivery.data_to_deliver if delivery.data_to_deliver.present?
    end

    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: "[iDocus][#{@deliveries.first.deliver_to}] Import d'écriture")
  end
end
