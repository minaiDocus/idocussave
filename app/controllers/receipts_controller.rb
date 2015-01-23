# -*- encoding : UTF-8 -*-
class ReceiptsController < PaperProcessesController
  def index
    paper_processes = PaperProcess.receipts.where(
      :created_at.gte => @current_time.beginning_of_month,
      :created_at.lte => @current_time.end_of_month
    )
    respond_to do |format|
      format.html do
        @grouped_paper_processes = paper_processes.desc(:created_at).group_by { |e| e.created_at.day }
        @paper_process = session[:receipt_paper_process]
        @paper_process ||= PaperProcess.new
      end
      format.csv do
        send_data(paper_processes.asc(:created_at).to_csv, type: 'text/csv', filename: "receipts_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  def create
    _params = paper_process_params
    @paper_process = PaperProcess.where(
      type: 'receipt',
      tracking_number: _params[:tracking_number]
    ).first
    @paper_process ||= PaperProcess.new(type: 'receipt')
    @paper_process.assign_attributes(_params)
    if @paper_process.persisted? && @paper_process.valid?
      session[:receipt_paper_process] = nil
      @paper_process.save
      flash[:success] = 'Modifié avec succès.'
    elsif @paper_process.save
      session[:receipt_paper_process] = nil
      @paper_process.user             = User.find_by_code @paper_process.customer_code
      @paper_process.organization     = @paper_process.user.try(:organization)
      @paper_process.save
      flash[:success] = 'Créé avec succès.'
    else
      session[:receipt_paper_process] = @paper_process
      flash[:error] = 'Donnée(s) invalide(s).'
    end
    redirect_to receipts_path
  end

private

  def paper_process_params
    params.require(:paper_process).permit(:tracking_number, :customer_code)
  end
end
