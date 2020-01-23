# -*- encoding : UTF-8 -*-
# Updates period with last subscription informations
class UpdateOrganizationPeriod
  def initialize(period)
    @period          = period
    @organization    = period.organization
  end

  def fetch_all
    @period.with_lock do
      time = @period.start_date.beginning_of_month + 15.days

      @customers_periods = Period.where(user_id: @organization.customers.active_at(time.to_date).map(&:id)).where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date)

      reset_quota
      fill_excess_max_values

      @customers_periods.each do |c_period|
        UpdatePeriodDataService.new(c_period).execute if c_period.is_valid_for_quota_organization
      end

      create_excess_order

      UpdatePeriodPriceService.new(@period).execute
    end
  end

  private

  def fill_excess_max_values
    @period.max_sheets_authorized               = 0
    @period.max_upload_pages_authorized         = 0
    @period.max_dematbox_scan_pages_authorized  = 0
    @period.max_preseizure_pieces_authorized    = 0
    @period.max_expense_pieces_authorized       = 0
    @period.max_paperclips_authorized           = 0
    @period.max_oversized_authorized            = 0

    @customers_periods.each do |c_period|
      if c_period.is_valid_for_quota_organization
        @period.max_sheets_authorized               += c_period.max_sheets_authorized || 0
        @period.max_upload_pages_authorized         += c_period.max_upload_pages_authorized || 0
        @period.max_dematbox_scan_pages_authorized  += c_period.max_dematbox_scan_pages_authorized || 0
        @period.max_preseizure_pieces_authorized    += c_period.max_preseizure_pieces_authorized || 0
        @period.max_expense_pieces_authorized       += c_period.max_expense_pieces_authorized || 0
        @period.max_paperclips_authorized           += c_period.max_paperclips_authorized || 0
        @period.max_oversized_authorized            += c_period.max_oversized_authorized || 0
      end
    end

    @period.save
  end

  def reset_quota
    @period.pages  = 0
    @period.pieces = 0

    @period.oversized  = 0
    @period.paperclips = 0

    @period.retrieved_pages  = 0
    @period.retrieved_pieces = 0

    @period.scanned_pages   = 0
    @period.scanned_pieces  = 0
    @period.scanned_sheets  = 0

    @period.uploaded_pages  = 0
    @period.uploaded_pieces = 0

    @period.dematbox_scanned_pages  = 0
    @period.dematbox_scanned_pieces = 0

    @period.expense_pieces    = 0
    @period.preseizure_pieces = 0

    @period.save
  end

  def create_excess_order
    @period.product_option_orders.where(name: 'excess_documents').destroy_all

    excesses_price = @period.excesses_price

    if excesses_price > 0
      option             = @period.product_option_orders.new
      option.title       = "Documents et écritures compta. en excès pour les dossiers mensuels"
      option.name        = 'excess_documents'
      option.duration    = 1
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = excesses_price

      option.save
    end
  end
end