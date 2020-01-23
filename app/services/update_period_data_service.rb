# -*- encoding : UTF-8 -*-
# Update metrics for called period
class UpdatePeriodDataService
  def initialize(period)
    @period = period
  end

  def execute
    return false if @period.organization

    @period.pages  = @period.documents.sum(:pages)      || 0
    @period.pieces = @period.documents.sum(:pieces)     || 0

    @period.oversized  = @period.documents.sum(:oversized)  || 0
    @period.paperclips = @period.documents.sum(:paperclips) || 0

    @period.retrieved_pages  = @period.documents.sum(:retrieved_pages)         || 0
    @period.retrieved_pieces = @period.documents.sum(:retrieved_pieces)        || 0

    @period.scanned_pages   = @period.documents.sum(:scanned_pages)  || 0
    @period.scanned_pieces  = @period.documents.sum(:scanned_pieces) || 0
    @period.scanned_sheets  = @period.documents.sum(:scanned_sheets) || 0

    @period.uploaded_pages  = @period.documents.sum(:uploaded_pages)  || 0
    @period.uploaded_pieces = @period.documents.sum(:uploaded_pieces) || 0

    @period.dematbox_scanned_pages  = @period.documents.sum(:dematbox_scanned_pages)  || 0
    @period.dematbox_scanned_pieces = @period.documents.sum(:dematbox_scanned_pieces) || 0

    @period.expense_pieces    = expense_pieces_count
    @period.preseizure_pieces = preseizure_pieces_count

    set_tags
    set_delivery_state

    set_organization_period_data_count

    @period.save
  end

  private


  def preseizure_pieces_count
    @preseizure_pieces_count ||= Pack::Report::Preseizure.unscoped.where(report_id: report_ids).where.not(piece_id: [nil]).count
  end


  def expense_pieces_count
    @expense_pieces_count ||= Pack::Report::Expense.where(report_id: report_ids).count
  end


  def set_tags
    tags = []

    @period.documents.each do |document|
      name = document.name.split

      case @period.duration
      when 1
        tags << "b_#{name[1]} y_#{name[2][0..3]} m_#{name[2][4..5].to_i}"
      when 3
        tags << "b_#{name[1]} y_#{name[2][0..3]} t_#{name[2][5]}"
      when 12
        tags << "b_#{name[1]} y_#{name[2][0..3]}"
      end
    end

    @period.documents_name_tags = tags
  end


  def set_delivery_state
    @period.delivery_state = 'delivered' if @period.scanned_sheets > 0
  end


  def document_ids
    @document_ids ||= @period.documents.distinct
  end


  def report_ids
    @report_ids ||= Pack::Report.where(document_id: document_ids).pluck(:id)
  end

  def set_organization_period_data_count
    if @period.is_valid_for_quota_organization
      organization_period = @period.user.organization.subscription.find_or_create_period(@period.start_date)

      organization_period.pages  += @period.pages    || 0
      organization_period.pieces += @period.pieces   || 0

      organization_period.oversized  += @period.oversized  || 0
      organization_period.paperclips += @period.paperclips || 0

      organization_period.retrieved_pages  += @period.retrieved_pages   || 0
      organization_period.retrieved_pieces += @period.retrieved_pieces  || 0

      organization_period.scanned_pages   += @period.scanned_pages  || 0
      organization_period.scanned_pieces  += @period.scanned_pieces || 0
      organization_period.scanned_sheets  += @period.scanned_sheets || 0

      organization_period.uploaded_pages  += @period.uploaded_pages  || 0
      organization_period.uploaded_pieces += @period.uploaded_pieces || 0

      organization_period.dematbox_scanned_pages  += @period.dematbox_scanned_pages  || 0
      organization_period.dematbox_scanned_pieces += @period.dematbox_scanned_pieces || 0

      organization_period.expense_pieces    += @period.expense_pieces    || 0
      organization_period.preseizure_pieces += @period.preseizure_pieces || 0

      organization_period.save
    end
  end
end
