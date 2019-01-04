# -*- encoding : UTF-8 -*-
class PreAssignmentDeliveryMailer < ActionMailer::Base
  def notify_deliveries(deliveries, addresses)
    @deliveries = deliveries
    @deliver_to = @deliveries.first.deliver_to

    extension = 'txt'
    extension = 'xml' if @deliver_to == 'ibiza'

    @deliveries.each do |delivery|
      attachments["#{delivery.id}.#{extension}"] = delivery.data_to_deliver if delivery.data_to_deliver.present?
    end

    addresses.delete('emmanuel.pliez@ibizasoftware.fr') if @deliver_to != 'ibiza'
    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: "[iDocus][#{@deliver_to}] Import d'écriture")
  end
end
