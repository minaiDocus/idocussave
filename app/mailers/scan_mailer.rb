# -*- encoding : UTF-8 -*-
class ScanMailer < ActionMailer::Base
  def notify_not_delivered(emails, pack_names)
    @pack_names = pack_names
    mail(to: emails, subject: "[iDocus] #{pack_names.size} document(s) scanné(s) mais non livré(s)")
  end

  def notify_uncompleted_delivery(emails, deliveries)
    @deliveries = deliveries
    mail(to: emails, subject: "[iDocus] #{deliveries.size} livraison(s) incomplète(s)")
  end
end
