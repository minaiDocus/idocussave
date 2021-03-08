# frozen_string_literal: true

class KitsController < PaperProcessesController
  # GET /kits
  def index
    paper_processes = PaperProcess.kits.where('created_at >= ? AND created_at <= ?', @current_time.beginning_of_month, @current_time.end_of_month)

    respond_to do |format|
      format.html do
        @grouped_paper_processes = paper_processes.order(created_at: :desc).group_by { |e| e.created_at.day }

        @paper_process = PaperProcess.where(id: session[:kit_paper_process_id]).first

        @paper_process ||= PaperProcess.new journals_count: 0, periods_count: 0
      end
      format.csv do
        send_data(PaperProcess.to_csv(paper_processes.order(created_at: :asc)), type: 'text/csv', filename: "kits_#{@current_time.strftime('%Y_%m')}.csv")
      end
    end
  end

  # POST /kits
  def create
    _params = paper_process_params

    _params[:customer_code] = CustomUtils.replace_code_of(_params[:customer_code])

    @paper_process = PaperProcess.where(type: 'kit', tracking_number: _params[:tracking_number]).first

    @paper_process ||= PaperProcess.new(type: 'kit')

    @paper_process.assign_attributes(_params)

    if @paper_process.persisted? && @paper_process.valid?
      session[:kit_paper_process_id] = nil

      @paper_process.save

      flash[:success] = 'Modifié avec succès.'
    elsif @paper_process.save
      session[:kit_paper_process_id] = nil

      @paper_process.user         = User.find_by_code @paper_process.customer_code
      @paper_process.organization = @paper_process.user.try(:organization)

      @paper_process.save

      flash[:success] = 'Créé avec succès.'
    else
      session[:kit_paper_process_id] = @paper_process.id
      flash[:error]               = 'Donnée(s) invalide(s).'
    end

    redirect_to kits_path
  end

  private

  def paper_process_params
    params.require(:paper_process).permit(
      :tracking_number,
      :customer_code,
      :journals_count,
      :periods_count,
      :order_id
    )
  end
end
