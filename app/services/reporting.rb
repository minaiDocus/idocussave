# -*- encoding : UTF-8 -*-
class Reporting
  class << self
    def update(pack)
      remaining_dividers = pack.dividers.size
      time = pack.created_at
      while remaining_dividers > 0
        period = pack.owner.find_or_create_scan_subscription.find_or_create_period(time)
        is_monthly = period.duration == 1
        current_dividers = pack.dividers.of_period(time, is_monthly)
        if current_dividers.any?
          p_metadata = find_or_create_periodic_metadata(pack, period.start_at, period.end_at, period)
          if p_metadata
            current_pages = pack.pages.of_period(time, is_monthly)
            p_metadata.pieces                  = current_dividers.pieces.count
            p_metadata.pages                   = current_pages.count
            p_metadata.scanned_pieces          = current_dividers.scanned.pieces.count
            p_metadata.scanned_sheets          = current_dividers.scanned.sheets.count
            p_metadata.scanned_pages           = current_pages.scanned.count
            p_metadata.dematbox_scanned_pieces = current_dividers.dematbox_scanned.pieces.count
            p_metadata.dematbox_scanned_pages  = current_pages.dematbox_scanned.count
            p_metadata.uploaded_pieces         = current_dividers.uploaded.pieces.count
            p_metadata.uploaded_pages          = current_pages.uploaded.count
            p_metadata.save
          end
          if p_metadata.pages - p_metadata.uploaded_pages > 0
            period.delivery.update_attributes(state: 'delivered')
          end
        end
        remaining_dividers -= current_dividers.count
        time += period.duration.month
      end
    end

    def find_periodic_metadata(pack, start_time, end_time)
      p_metadata = pack.periodic_metadata.for_time(start_time,end_time).first
      p_metadata = Pack::PeriodicMetadata.where(name: pack.name).for_time(start_time,end_time).first unless p_metadata
      p_metadata
    end

    def find_or_create_periodic_metadata(pack, start_time, end_time, period)
      p_metadata = find_periodic_metadata(pack, start_time, end_time)
      if p_metadata
        unless p_metadata.period && p_metadata.pack
          p_metadata.period = period
          p_metadata.pack = pack
          p_metadata.save
        end
        p_metadata
      else
        p_metadata = Pack::PeriodicMetadata.new
        p_metadata.name = pack.name
        p_metadata.period = period
        p_metadata.pack = pack
        p_metadata.save
        p_metadata
      end
    end
  end
end
