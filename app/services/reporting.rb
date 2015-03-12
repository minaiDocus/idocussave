# -*- encoding : UTF-8 -*-
class Reporting
  class << self
    def update(pack)
      remaining_dividers = pack.dividers.size
      time = pack.created_at
      while remaining_dividers > 0
        period = pack.owner.find_or_create_subscription.find_or_create_period(time)
        is_monthly = period.duration == 1
        current_dividers = pack.dividers.of_period(time, is_monthly)
        if current_dividers.any?
          period_document = find_or_create_period_document(pack, period.start_at, period.end_at, period)
          if period_document
            current_pages = pack.pages.of_period(time, is_monthly)
            period_document.pieces                  = current_dividers.pieces.count
            period_document.pages                   = current_pages.count
            period_document.scanned_pieces          = current_dividers.scanned.pieces.count
            period_document.scanned_sheets          = current_dividers.scanned.sheets.count
            period_document.scanned_pages           = current_pages.scanned.count
            period_document.dematbox_scanned_pieces = current_dividers.dematbox_scanned.pieces.count
            period_document.dematbox_scanned_pages  = current_pages.dematbox_scanned.count
            period_document.uploaded_pieces         = current_dividers.uploaded.pieces.count
            period_document.uploaded_pages          = current_pages.uploaded.count
            period_document.fiduceo_pieces          = current_dividers.fiduceo.pieces.count
            period_document.fiduceo_pages           = current_pages.fiduceo.count
            period_document.save
          end
          if period_document.pages - period_document.uploaded_pages > 0
            period.delivery.update_attributes(state: 'delivered')
          end
        end
        remaining_dividers -= current_dividers.count
        time += period.duration.month
      end
    end

    def find_period_document(pack, start_time, end_time)
      period_document = pack.period_documents.for_time(start_time,end_time).first
      period_document = PeriodDocument.where(name: pack.name).for_time(start_time,end_time).first unless period_document
      period_document
    end

    def find_or_create_period_document(pack, start_time, end_time, period)
      period_document = find_period_document(pack, start_time, end_time)
      if period_document
        unless period_document.period && period_document.pack
          period_document.period = period
          period_document.pack = pack
          period_document.save
        end
        period_document
      else
        period_document = PeriodDocument.new
        period_document.name         = pack.name
        period_document.period       = period
        period_document.user         = pack.owner
        period_document.organization = pack.organization
        period_document.pack         = pack
        period_document.save
        period_document
      end
    end
  end
end
