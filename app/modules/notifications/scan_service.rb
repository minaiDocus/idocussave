# -*- encoding : UTF-8 -*-
# Generic methods for scanned documents
class Notifications::ScanService < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  # Send mail to concerned people in settings
  def notify_not_delivered
    @not_delivered = not_delivered

    emails = Settings.first.notify_scans_not_delivered_to

    if !@not_delivered.empty? && emails.any?
      ScanMailer.notify_not_delivered(emails, @not_delivered).deliver_later
    else
      false
    end
  end

  #Send mail for uncomplete scan delivery
  def notify_uncompleted_delivery
    deliveries = @arguments[:deliveries]

    if deliveries.any? && (emails = Settings.first.notify_scans_not_delivered_to).any?
      ScanMailer.notify_uncompleted_delivery(emails, deliveries).deliver_later
    else
      false
    end
  end

  private

  # List not delivered temp packs
  def not_delivered
    PeriodDocument.scanned.where("scanned_at >= ?", 30.days.ago).select do |scan|
      result = false

      temp_pack = TempPack.where(name: scan.name).first

      if temp_pack
        # NOTE minus 10 days because PPP delivers a few days before entering the information inside iDocus
        result = temp_pack.temp_documents.scan.where("created_at >= ?", scan.scanned_at-10.days).empty?
      else
        result = true
      end

      print (result ? '!' : '.')

      result
    end.map(&:name)
  end

end
