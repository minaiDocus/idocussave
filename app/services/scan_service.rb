# -*- encoding : UTF-8 -*-
class ScanService
  class << self
    def not_delivered
      PeriodDocument.scanned.where(:scanned_at.gte => 30.days.ago).select do |scan|
        result = false
        temp_pack = TempPack.where(name: scan.name).first
        if temp_pack
          result = temp_pack.temp_documents.scan.where(:created_at.gte => scan.scanned_at).size == 0
        else
          result = true
        end
        print (result ? '!' : '.')
        result
      end.map(&:name)
    end

    def notify_not_delivered
      @not_delivered = not_delivered
      emails = Settings.notify_scans_not_delivered_to
      if @not_delivered.size > 0 && emails.any?
        ScanMailer.notify_not_delivered(emails, @not_delivered).deliver
      else
        false
      end
    end
  end
end
