# frozen_string_literal: true

class ScansController < PaperProcessesController
  before_action :load_scanned_by
  before_action :load_resource, only: :index

  # GET /scans
  def index
    respond_to do |format|
      format.html do
        @document = PeriodDocument.where(id: session[:document]).first || PeriodDocument.new
        @old_document = PeriodDocument.where(id: session[:old_document]).first
      end
      format.csv do
        send_data(PeriodDocument.to_csv(@all_documents.order(created_at: :asc)), type: 'text/csv', filename: "scans_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  # POST /scans
  def create
    _params = period_document_params

    _params[:name] = CustomUtils.replace_code_of(_params[:name])

    if _params && _params[:name] && _params[:paperclips] && _params[:oversized]
      _params[:name].tr!('_', ' ')
      _params[:name].strip!

      if _params[:name].present? && !_params[:name].end_with?(' all')
        _params[:name] << ' all'
      end

      @document = PeriodDocument.where(name: _params[:name]).order(created_at: :desc).first

      if @document.nil? || (@document&.period && @document.period.end_date < Date.today)
        @document = PeriodDocument.new
      end

      @document.assign_attributes(_params)

      if @document.persisted? && @document.valid?
        session[:document] = nil
        session[:old_document] = @document.reload.id
        session[:new_document] = {}
        session[:new_document][:name] = _params[:name]
        session[:new_document][:oversized]  = _params[:oversized].to_i
        session[:new_document][:paperclips] = _params[:paperclips].to_i
      else
        @document.user = User.where(code: @document.name.split[0]).first
        @document.scanned_at = Time.now
        @document.scanned_by = @scanned_by
        @document.organization = @document.user.try(:organization)

        if @document.user && @document.save
          create_paper_process(@document)

          if @document.period
            Billing::UpdatePeriodData.new(@document.period).execute
            Billing::UpdatePeriodPrice.new(@document.period).execute
          end

          flash[:success] = 'Créé avec succès.'
          flash[:error] = nil
          session[:document] = nil
        else
          @document.errors.add(:name, :invalid) unless @document.user

          flash[:success] = nil
          flash[:error] = "Donnée(s) invalide(s). [ #{@document.errors.messages.to_s} ]"
          session[:document] = @document.id
        end
      end
    end

    redirect_to scans_path
  end

  # PUT /scans/:id/add
  def add
    document = PeriodDocument.find(params[:id])

    document.oversized += params[:oversized].to_i
    document.paperclips += params[:paperclips].to_i
    document.updated_at = Time.now
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by

    document.save

    create_paper_process(document)

    if document.period
      Billing::UpdatePeriodData.new(document.period).execute
      Billing::UpdatePeriodPrice.new(document.period).execute
    end

    reset_waiting_document

    flash[:success] = 'Modifié avec succès.'
    redirect_to scans_path
  end

  # PUT /scans/:id/overwrite
  def overwrite
    document = PeriodDocument.find(params[:id])

    document.oversized     = params[:oversized].to_i
    document.paperclips    = params[:paperclips].to_i
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by

    document.save

    create_paper_process(document)

    if document.period
      Billing::UpdatePeriodData.new(document.period).execute
      Billing::UpdatePeriodPrice.new(document.period).execute
    end

    reset_waiting_document

    flash[:success] = 'Remplacé avec succès.'
    redirect_to scans_path
  end

  # GET /scans/cancel
  def cancel
    reset_waiting_document

    redirect_to scans_path
  end

  protected

  # REFACTOR
  def is_return_labels_authorized?
    # (@user && @user['is_return_labels_authorized']) || current_user
    true
  end
  helper_method :is_return_labels_authorized?

  private

  def load_scanned_by
    @scanned_by = 'ppp'
  end

  def load_resource
    @all_documents = PeriodDocument.where('scanned_at >= ? AND scanned_at <= ?', @current_time.beginning_of_month, @current_time.end_of_month).where.not(scanned_at: nil)
    # @all_documents = @all_documents.where(scanned_by: @scanned_by) if @scanned_by.present?

    @groups = @all_documents.group_by { |e| e.scanned_at.day }

    @documents = PeriodDocument.where('scanned_at >= ? AND scanned_at <= ?', @current_time.beginning_of_day, @current_time.end_of_day).where.not(scanned_at: nil).order(scanned_at: :desc)
    # @documents = @documents.where(scanned_by: @scanned_by) if @scanned_by.present?
  end

  def reset_waiting_document
    session[:document] = nil
    session[:old_document] = nil
    session[:new_document] = nil
  end

  def create_paper_process(document)
    unless document.paper_process
      paper_process = PaperProcess.new

      paper_process.type            = 'scan'
      paper_process.user            = document.user
      paper_process.pack_name = document.name
      paper_process.organization = document.user.try(:organization)
      paper_process.customer_code   = document.user.try(:code)
      paper_process.period_document = document

      paper_process.save
    end
  end

  def period_document_params
    params.require(:period_document).permit(:name, :paperclips, :oversized)
  end
end
