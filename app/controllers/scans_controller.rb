# -*- encoding : UTF-8 -*-
class ScansController < PaperProcessesController
  before_filter :load_scanned_by
  before_filter :load_resource, only: :index

  def index
    respond_to do |format|
      format.html do
        @document = session[:document] || PeriodDocument.new
      end
      format.csv do
        send_data(@all_documents.asc(:scanned_at).to_csv, type: 'text/csv', filename: "scans_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  def create
    if params[:period_document] && params[:period_document][:name] && params[:period_document][:paperclips] && params[:period_document][:oversized]
      params[:period_document][:name].gsub!('_',' ')
      params[:period_document][:name].strip!
      if params[:period_document][:name].present? && !params[:period_document][:name].match(/ all$/)
        params[:period_document][:name] << ' all'
      end
      @document = PeriodDocument.where(name: params[:period_document][:name]).desc(:created_at).first
      if (@document.nil?) || (@document && @document.period && @document.period.end_at < Time.now)
        @document = PeriodDocument.new
      end
      @document.assign_attributes(params[:period_document])
      if @document.persisted? && @document.valid?
        session[:document] = nil
        session[:old_document] = @document.reload
        session[:new_document] = {}
        session[:new_document][:name] = params[:period_document][:name]
        session[:new_document][:paperclips] = params[:period_document][:paperclips].to_i
        session[:new_document][:oversized] = params[:period_document][:oversized].to_i
      else
        @document.user         = User.where(code: @document.name.split[0]).first
        @document.organization = @document.user.try(:organization)
        @document.scanned_at   = Time.now
        @document.scanned_by   = @scanned_by
        if @document.save
          create_paper_process(@document)
          if @document.period
            UpdatePeriodDataService.new(@document.period).execute
            UpdatePeriodPriceService.new(@document.period).execute
          end
          flash[:success] = 'Créé avec succès.'
          flash[:error] = nil
          session[:document] = nil
        else
          flash[:success] = nil
          flash[:error] = 'Donnée(s) invalide(s).'
          session[:document] = @document
        end
      end
    end
    redirect_to scans_path
  end

  def add
    document = PeriodDocument.find params[:id]
    document.paperclips += params[:paperclips].to_i
    document.oversized += params[:oversized].to_i
    document.updated_at = Time.now
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
    create_paper_process(document)
    if document.period
      UpdatePeriodDataService.new(document.period).execute
      UpdatePeriodPriceService.new(document.period).execute
    end
    flash[:success] = 'Modifié avec succès.'
    reset_waiting_document
    redirect_to scans_path
  end

  def overwrite
    document = PeriodDocument.find params[:id]
    document.paperclips = params[:paperclips].to_i
    document.oversized = params[:oversized].to_i
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
    create_paper_process(document)
    if document.period
      UpdatePeriodDataService.new(document.period).execute
      UpdatePeriodPriceService.new(document.period).execute
    end
    reset_waiting_document
    flash[:success] = 'Remplacé avec succès.'
    redirect_to scans_path
  end

  def cancel
    reset_waiting_document
    redirect_to scans_path
  end

protected

  def is_return_labels_authorized?
    (@user && @user[3]) or current_user
  end
  helper_method :is_return_labels_authorized?

private

  def load_scanned_by
    @scanned_by = @user.try(:[], 2)
  end

  def load_resource
    @all_documents = PeriodDocument.where(
      :scanned_at.gte => @current_time.beginning_of_month,
      :scanned_at.lte => @current_time.end_of_month
    )
    @all_documents = @all_documents.where(scanned_by: /#{@scanned_by}/) if @scanned_by.present?
    @groups = @all_documents.group_by { |e| e.scanned_at.day }
    @documents = PeriodDocument.where(
      :scanned_at.gte => @current_time.beginning_of_day,
      :scanned_at.lte => @current_time.end_of_day
    ).desc(:scanned_at)
    @documents = @documents.where(scanned_by: /#{@scanned_by}/) if @scanned_by.present?
  end

  def reset_waiting_document
    session[:old_document] = nil
    session[:new_document] = nil
    session[:document]     = nil
  end

  def create_paper_process(document)
    unless document.paper_process
      paper_process = PaperProcess.new
      paper_process.organization    = document.user.try(:organization)
      paper_process.user            = document.user
      paper_process.period_document = document
      paper_process.type            = 'scan'
      paper_process.customer_code   = document.user.try(:code)
      paper_process.pack_name       = document.name
      paper_process.save
    end
  end
end
