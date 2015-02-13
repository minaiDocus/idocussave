# -*- encoding : UTF-8 -*-
class ScansController < PaperProcessesController
  before_filter :load_scanned_by
  before_filter :load_resource, only: :index

  def index
    respond_to do |format|
      format.html do
        @document = session[:document] || Scan::Document.new
      end
      format.csv do
        send_data(@all_documents.asc(:scanned_at).to_csv, type: 'text/csv', filename: "scans_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  def create
    if params[:scan_document] && params[:scan_document][:name] && params[:scan_document][:paperclips] && params[:scan_document][:oversized]
      params[:scan_document][:name].gsub!('_',' ')
      params[:scan_document][:name].strip!
      if params[:scan_document][:name].present? && !params[:scan_document][:name].match(/ all$/)
        params[:scan_document][:name] << ' all'
      end
      @document = Scan::Document.where(name: params[:scan_document][:name]).desc(:created_at).first
      if (@document.nil?) || (@document && @document.period && @document.period.end_at < Time.now)
        @document = Scan::Document.new
      end
      @document.assign_attributes(params[:scan_document])
      if @document.persisted? && @document.valid?
        session[:document] = nil
        session[:old_document] = @document.reload
        session[:new_document] = {}
        session[:new_document][:name] = params[:scan_document][:name]
        session[:new_document][:paperclips] = params[:scan_document][:paperclips].to_i
        session[:new_document][:oversized] = params[:scan_document][:oversized].to_i
      else
        @document.user         = User.where(code: @document.name.split[0]).first
        @document.organization = @document.user.try(:organization)
        @document.scanned_at   = Time.now
        @document.scanned_by   = @scanned_by
        if @document.save
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
    document = Scan::Document.find params[:id]
    document.paperclips += params[:paperclips].to_i
    document.oversized += params[:oversized].to_i
    document.updated_at = Time.now
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
    flash[:success] = 'Modifié avec succès.'
    reset_waiting_document
    redirect_to scans_path
  end

  def overwrite
    document = Scan::Document.find params[:id]
    document.paperclips = params[:paperclips].to_i
    document.oversized = params[:oversized].to_i
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
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
    @all_documents = Scan::Document.where(
      :scanned_at.gte => @current_time.beginning_of_month,
      :scanned_at.lte => @current_time.end_of_month
    )
    @all_documents = @all_documents.where(scanned_by: /#{@scanned_by}/) if @scanned_by.present?
    @groups = @all_documents.group_by { |e| e.scanned_at.day }
    @documents = Scan::Document.where(
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
end
