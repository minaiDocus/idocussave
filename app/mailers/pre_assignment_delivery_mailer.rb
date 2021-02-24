# -*- encoding : UTF-8 -*-
class PreAssignmentDeliveryMailer < ActionMailer::Base
  def notify_deliveries(deliveries, addresses)
    @deliveries = deliveries
    @deliver_to = @deliveries.first.deliver_to

    extension = 'txt'
    extension = 'xml' if @deliver_to == 'ibiza'

    @deliveries.each do |delivery|
      begin
        if delivery.data_to_deliver.present?
          attachments["#{delivery.id}.#{extension}"] = delivery.data_to_deliver
        elsif File.exist?(delivery.cloud_content_object.path)
          attachments["#{delivery.id}.#{extension}"] = File.read(delivery.cloud_content_object.path)
        end
      rescue => e
        log_document = {
          subject: "[PreAssignmentDeliveryMailer] active Storage can't read file",
          name: "PreAssignmentDeliveryMailer",
          error_group: "[pre-assignment-delivery-mailer] active Storage can't read file",
          erreur_type: "Active Storage, can't read file",
          date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
          more_information: {
            delivery: delivery.inspect,
            error: e.to_s
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end
    end

    addresses.delete('emmanuel.pliez@ibizasoftware.fr') if @deliver_to != 'ibiza'
    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: "[iDocus][#{@deliver_to}] Import d'écriture")
  end
end
