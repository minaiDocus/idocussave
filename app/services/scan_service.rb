# -*- encoding : UTF-8 -*-
# Generic methods for scanned documents
module ScanService
  # List not delivered temp packs
  def self.not_delivered
    PeriodDocument.scanned.where("scanned_at >= ?", 30.days.ago).select do |scan|
      result = false

      temp_pack = TempPack.where(name: scan.name).first

      if temp_pack
        result = temp_pack.temp_documents.scan.where("created_at >= ?", scan.scanned_at).empty?
      else
        result = true
      end

      print (result ? '!' : '.')

      result
    end.map(&:name)
  end


  # Send mail to concerned people in settings
  def self.notify_not_delivered
    @not_delivered = not_delivered

    emails = Settings.first.notify_scans_not_delivered_to

    if !@not_delivered.empty? && emails.any?
      ScanMailer.notify_not_delivered(emails, @not_delivered).deliver_later
    else
      false
    end
  end
end
