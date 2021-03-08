# frozen_string_literal: true

class ReceiptsController < PaperProcessesController
  def index
    paper_processes = PaperProcess.receipts.where('created_at >= ? AND created_at <= ?', @current_time.beginning_of_month, @current_time.end_of_month)

    respond_to do |format|
      format.html do
        @grouped_paper_processes = paper_processes.order(created_at: :desc).group_by { |e| e.created_at.day }
        @paper_process = PaperProcess.where(id: session[:receipt_paper_process_id]).first
        @paper_process ||= PaperProcess.new
      end
      format.csv do
        send_data(PaperProcess.to_csv(paper_processes.order(created_at: :asc)), type: 'text/csv', filename: "receipts_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  def create
    _params = paper_process_params

    _params[:customer_code] = CustomUtils.replace_code_of(_params[:customer_code])

    user = User.find_by_code(_params[:customer_code])
    if user
      user.options.with_lock(timeout: 1, retries: 10, retry_sleep: 0.1) do
        @paper_process = PaperProcess.where(type: 'receipt', tracking_number: _params[:tracking_number]).first
        @paper_process ||= PaperProcess.new(type: 'receipt')
        @paper_process.assign_attributes(_params)
        if @paper_process.persisted? && @paper_process.valid?
          session[:receipt_paper_process_id] = nil
          @paper_process.save
          flash[:success] = 'Modifié avec succès.'
        elsif @paper_process.save
          session[:receipt_paper_process_id] = nil
          @paper_process.user         = user
          @paper_process.organization = user.organization
          @paper_process.save
          flash[:success] = 'Créé avec succès.'
        else
          session[:receipt_paper_process_id] = @paper_process.id
          flash[:error] = 'Donnée(s) invalide(s).'
        end
      end
    else
      paper_process = PaperProcess.new(type: 'receipt')
      paper_process.assign_attributes(_params)
      paper_process.valid?
      session[:receipt_paper_process_id] = paper_process.id
      flash[:error] = 'Donnée(s) invalide(s).'
    end
    redirect_to receipts_path
  end

  private

  def paper_process_params
    params.require(:paper_process).permit(:tracking_number, :customer_code)
  end
end
