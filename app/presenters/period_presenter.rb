# -*- encoding : UTF-8 -*-
class PeriodPresenter
  def initialize(period, viewer)
    @period = period
    @owner  = @period.user
    @viewer = viewer || @owner
    @viewer = Collaborator.new(@viewer) if @viewer.collaborator?
  end


  def render_json
    hash = { documents: documents_json }
    hash[:options] = options_json if can_display_options?
    hash
  end


  def can_display_options?
    @viewer.is_admin || (@viewer.is_prescriber && @viewer.customers.include?(@owner)) ||
      (
        @viewer.organization.try(:is_detail_authorized) &&
        (@viewer == @owner || (@viewer.is_guest && @viewer.accounts.include?(@owner)))
      )
  end


  def documents_json
    total = {}
    total[:pages]  = 0
    total[:pieces] = 0
    total[:pre_assignments] = 0

    total[:scanned_pages]  = 0
    total[:scanned_pieces] = 0
    total[:scanned_sheets] = 0

    total[:dematbox_scanned_pages]  = 0
    total[:dematbox_scanned_pieces] = 0

    total[:uploaded_pages]  = 0
    total[:uploaded_pieces] = 0

    total[:retrieved_pages]  = 0
    total[:retrieved_pieces] = 0

    total[:oversized]  = 0
    total[:paperclips] = 0

    lists = []

    @period.documents.each do |document|
      list = {}
      list[:name] = document.name

      begin
        pack = document.pack
        if pack
          list[:historic] = pack.content_historic.each { |h| h[:date] = h[:date].strftime('%d/%m/%Y') }
          list[:link] = Rails.application.routes.url_helpers.account_documents_path(pack_name: pack.name)
          pre_assignments = document.report ? (Pack::Report::Preseizure.unscoped.where(report_id: document.report).where.not(piece_id: nil).count  + document.report.expenses.count) : 0
        else
          list[:historic] = ''
          list[:link] = '#'
          pre_assignments = 0
        end
      rescue
        list[:historic] = ''
        list[:link] = '#'
        pre_assignments = 0
      end

      list[:pages]  = document.pages.to_s
      list[:pieces] = document.pieces.to_s
      list[:pre_assignments] = pre_assignments.to_s

      list[:scanned_pages]  = document.scanned_pages.to_s
      list[:scanned_pieces] = document.scanned_pieces.to_s
      list[:scanned_sheets] = document.scanned_sheets.to_s

      list[:dematbox_scanned_pages]  = document.dematbox_scanned_pages.to_s
      list[:dematbox_scanned_pieces] = document.dematbox_scanned_pieces.to_s

      list[:uploaded_pages]  = document.uploaded_pages.to_s
      list[:uploaded_pieces] = document.uploaded_pieces.to_s

      list[:retrieved_pages]  = document.retrieved_pages.to_s
      list[:retrieved_pieces] = document.retrieved_pieces.to_s

      list[:oversized]  = document.oversized.to_s
      list[:paperclips] = document.paperclips.to_s

      if document.report.try(:type)
        if document.report.try(:type) == 'NDF'
          list[:report_id] = document.report.try(:id) || '#'
          list[:report_type] = document.report.try(:type) || ''
        elsif @viewer.is_admin || (@viewer.is_prescriber && @viewer.customers.include?(@owner))
          list[:report_id] = document.report.try(:id) || '#'
          list[:report_type] = document.report.try(:type) || ''
        else
          list[:report_id] = '#'
        end
      else
        list[:report_id] = '#'
      end

      lists << list

      total[:pages]  += document.pages
      total[:pieces] += document.pieces
      total[:pre_assignments] += pre_assignments

      total[:scanned_pages]  += document.scanned_pages
      total[:scanned_pieces] += document.scanned_pieces
      total[:scanned_sheets] += document.scanned_sheets

      total[:dematbox_scanned_pages]  += document.dematbox_scanned_pages
      total[:dematbox_scanned_pieces] += document.dematbox_scanned_pieces

      total[:uploaded_pages]  += document.uploaded_pages
      total[:uploaded_pieces] += document.uploaded_pieces

      total[:retrieved_pages]  += document.retrieved_pages
      total[:retrieved_pieces] += document.retrieved_pieces

      total[:oversized]  += document.oversized
      total[:paperclips] += document.paperclips
    end

    total[:pages]  = total[:pages].to_s
    total[:pieces] = total[:pieces].to_s
    total[:pre_assignments] = total[:pre_assignments].to_s

    total[:scanned_pages]  = total[:scanned_pages].to_s
    total[:scanned_pieces] = total[:scanned_pieces].to_s
    total[:scanned_sheets] = total[:scanned_sheets].to_s

    total[:dematbox_scanned_pages]  = total[:dematbox_scanned_pages].to_s
    total[:dematbox_scanned_pieces] = total[:dematbox_scanned_pieces].to_s

    total[:uploaded_pages]  = total[:uploaded_pages].to_s
    total[:uploaded_pieces] = total[:uploaded_pieces].to_s

    total[:retrieved_pages]  = total[:retrieved_pages].to_s
    total[:retrieved_pieces] = total[:retrieved_pieces].to_s

    total[:oversized]  = total[:oversized].to_s
    total[:paperclips] = total[:paperclips].to_s

    {
      list: lists,
      total: total,
      excess: {
        sheets: @period.excess_sheets.to_s,
        oversized:  @period.excess_oversized.to_s,
        paperclips: @period.excess_paperclips.to_s,
        compta_pieces:   @period.excess_compta_pieces.to_s,
        uploaded_pages: @period.excess_uploaded_pages.to_s,
        dematbox_scanned_pages: @period.excess_dematbox_scanned_pages.to_s
      },
      delivery: @period.delivery_state,
      is_valid_for_quota_organization: @period.is_valid_for_quota_organization
    }
  end


  def options_json
    lists = []

    @period.product_option_orders.by_position.each do |option|
      list = {}

      next unless option.position != -1

      list[:title] = option.title
      list[:price] = format_price option.price_in_cents_wo_vat
      list[:group_title] = option.group_title

      lists << list
    end

    _invoices = []

    if @period.organization || @period.user
      start_time = (@period.start_date + 1.month).beginning_of_month

      if @period.duration == 1
        end_time = start_time.end_of_month
      elsif @period.duration == 3
        end_time = start_time + 3.months - 1
      end

      _invoices = (@period.organization || @period.user).invoices.where("created_at >= ? AND created_at <= ?", start_time, end_time)

      _invoices = _invoices.map do |invoice|
        { number: invoice.number, link: invoice.cloud_content_object.url }
      end
    end

    {
      list:                          lists,
      excess_uploaded_pages:         format_price(@period.price_in_cents_of_excess_uploaded_pages),
      excess_scan:                   format_price(@period.price_in_cents_of_excess_scan),
      excess_dematbox_scanned_pages: format_price(@period.price_in_cents_of_excess_dematbox_scanned_pages),
      excess_compta_pieces:          format_price(@period.price_in_cents_of_excess_compta_pieces),
      excess_paperclips:             format_price(@period.price_in_cents_of_excess_paperclips),
      total:                         format_price(@period.price_in_cents_wo_vat),
      invoices:                      _invoices
    }
  end

  private


  def format_price(price_in_cents)
    ('%0.2f' % (price_in_cents / 100.0)).tr('.', ',')
  end
end
