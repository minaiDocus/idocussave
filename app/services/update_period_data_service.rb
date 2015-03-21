# -*- encoding : UTF-8 -*-
class UpdatePeriodDataService
  def initialize(period)
    @period = period
  end

  def execute
    @period.pieces                  = @period.documents.sum(:pieces)                  || 0
    @period.pages                   = @period.documents.sum(:pages)                   || 0
    @period.scanned_pieces          = @period.documents.sum(:scanned_pieces)          || 0
    @period.scanned_sheets          = @period.documents.sum(:scanned_sheets)          || 0
    @period.scanned_pages           = @period.documents.sum(:scanned_pages)           || 0
    @period.dematbox_scanned_pieces = @period.documents.sum(:dematbox_scanned_pieces) || 0
    @period.dematbox_scanned_pages  = @period.documents.sum(:dematbox_scanned_pages)  || 0
    @period.uploaded_pieces         = @period.documents.sum(:uploaded_pieces)         || 0
    @period.uploaded_pages          = @period.documents.sum(:uploaded_pages)          || 0
    @period.fiduceo_pieces          = @period.documents.sum(:fiduceo_pieces)          || 0
    @period.fiduceo_pages           = @period.documents.sum(:fiduceo_pages)           || 0
    @period.paperclips              = @period.documents.sum(:paperclips)              || 0
    @period.oversized               = @period.documents.sum(:oversized)               || 0
    @period.preseizure_pieces       = preseizure_pieces_count
    @period.expense_pieces          = expense_pieces_count

    set_tags
    set_delivery_state

    @period.save
  end

private

  def preseizure_pieces_count
    @preseizure_pieces_count ||= Pack::Report::Preseizure.where(
      :report_id.in => report_ids,
      :piece_id.nin => [nil]
    ).count
  end

  def expense_pieces_count
    @expense_pieces_count ||= Pack::Report::Expense.where(:report_id.in => report_ids).count
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
    if @period.scanned_sheets > 0
      @period.delivery.state = 'delivered'
    end
  end

  def document_ids
    @document_ids ||= @period.documents.distinct(:_id)
  end

  def report_ids
    @report_ids ||= Pack::Report.where(:document_id.in => document_ids).distinct(:_id)
  end
end
