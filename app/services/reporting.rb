# -*- encoding : UTF-8 -*-
module Reporting
  # Update billings information for a Specific Pack
  def self.update(pack)
    remaining_dividers = pack.dividers.size
    time = pack.created_at.localtime

    while remaining_dividers > 0
      period = pack.owner.subscription.find_or_create_period(time.to_date)
      current_dividers = pack.dividers.of_period(time, period.duration)

      if current_dividers.any?
        period_document = find_or_create_period_document(pack, period)
        if period_document
          current_pages = pack.pages.of_period(time, period.duration)
          period_document.pages  = Pack.count_pages_of current_pages
          period_document.pieces = current_dividers.pieces.count

          period_document.retrieved_pages  = Pack.count_pages_of current_pages.retrieved
          period_document.retrieved_pieces = current_dividers.retrieved.pieces.count

          period_document.scanned_pages  = Pack.count_pages_of current_pages.scanned
          period_document.scanned_pieces = current_dividers.scanned.pieces.count
          period_document.scanned_sheets = current_dividers.scanned.sheets.count

          period_document.uploaded_pages  = Pack.count_pages_of current_pages.uploaded
          period_document.uploaded_pieces = current_dividers.uploaded.pieces.count

          period_document.dematbox_scanned_pages  = Pack.count_pages_of current_pages.dematbox_scanned
          period_document.dematbox_scanned_pieces = current_dividers.dematbox_scanned.pieces.count

          period_document.save

          Billing::UpdatePeriodData.new(period_document.period).execute
          Billing::UpdatePeriodPrice.new(period_document.period).execute
        end

        if period_document.pages - period_document.uploaded_pages > 0
          period.update(delivery_state: 'delivered')
        end
      end

      remaining_dividers -= current_dividers.count
      time += period.duration.month
    end

    Billing::UpdateOrganizationPeriod.new(pack.organization.subscription.current_period).fetch_all(true)
  end

  def self.find_period_document(pack, start_date, end_date)
    PeriodDocument.where('name = ? OR pack_id = ?', pack.name, pack.id).
      for_time(start_date.to_time, end_date.to_time.end_of_day).first
  end

  def self.find_or_create_period_document(pack, period)
    period_document = find_period_document(pack, period.start_date, period.end_date)

    if period_document
      unless period_document.period && period_document.pack
        period_document.period = period
        period_document.pack = pack
        period_document.save
      end
      period_document
    else
      period_document = PeriodDocument.new
      period_document.user         = pack.owner
      period_document.pack         = pack
      period_document.name         = pack.name
      period_document.period       = period
      period_document.organization = pack.organization
      period_document.save
      period_document
    end
  end
end
