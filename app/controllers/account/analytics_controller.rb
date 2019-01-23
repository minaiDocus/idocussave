class Account::AnalyticsController < Account::AccountController
  before_action :load_customer
  before_action :load_default_analytic_by_pattern
  before_action :verify_rights

  def index
    result = IbizaAnalytic.new(@customer.ibiza_id, ibiza.access_token).list
    journal_analytic_references = @journal? JournalAnalyticReferences.new(@journal).get_analytic_references : nil
    pieces_analytic_references  = @pieces?  get_pieces_analytic_references : nil
    respond_to do |format|
      format.json { render json: { analytics: result, defaults: (pieces_analytic_references || journal_analytic_references) }.to_json, status: :ok }
    end
  end

  private

  def load_customer
    @customer = accounts.find_by(code: params[:code])
  end

  def load_default_analytic_by_pattern
    @journal  = (params[:pattern].present? && params[:type] == 'journal') ? @customer.account_book_types.where(name: params[:pattern]).first : nil
    @pieces   = (params[:pattern].present? && params[:type] == 'piece') ? Pack::Piece.where(id: params[:pattern]) : nil

    if @pieces
      journal_name = @pieces.collect(&:journal).uniq || []

      if journal_name.size == 1 && !@journal
        @journal  = @customer.account_book_types.where(name: journal_name.first).first || nil
      end
    end
  end

  def verify_rights
    unless @customer && @customer.ibiza_id.present? && @customer.uses_ibiza? && @customer.try(:softwares).try(:ibiza_compta_analysis_activated?) && ibiza.try(:configured?)
      respond_to do |format|
        format.json { render json: { message: 'Unauthorized' }, status: 401 }
      end
    end
  end

  def ibiza
    @ibiza ||= @customer.organization.ibiza
  end

  def get_pieces_analytic_references
    analytic_refs = @pieces.collect(&:analytic_reference_id).compact
    analytic_refs.uniq!
    result = nil

    if analytic_refs.size == 1
      analytic = @pieces.first.analytic_reference || nil

      if analytic
        result =  {
                    a1_name:       analytic['a1_name'].presence,
                    a1_references: JSON.parse(analytic['a1_references']),
                    a2_name:       analytic['a2_name'].presence,
                    a2_references: JSON.parse(analytic['a2_references']),
                    a3_name:       analytic['a3_name'].presence,
                    a3_references: JSON.parse(analytic['a3_references']),
                  }.with_indifferent_access
      end
    end
    result
  end
end
