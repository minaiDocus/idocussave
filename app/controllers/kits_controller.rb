# -*- encoding : UTF-8 -*-
class KitsController < PaperProcessesController
  def index
    @grouped_paper_processes = PaperProcess.kits.where(
      :created_at.gte => @current_time.beginning_of_month,
      :created_at.lte => @current_time.end_of_month
    ).group_by { |e| e.created_at.day }
    @paper_process = session[:paper_process]
    @paper_process ||= PaperProcess.new journals_count: 1, periods_count: 1
  end

  def create
    _params = paper_process_params
    @paper_process = PaperProcess.where(
      type:            'kit',
      tracking_number: _params[:tracking_number],
      customer_code:   _params[:customer_code]
    ).first
    @paper_process ||= PaperProcess.new(type: 'kit')
    @paper_process.assign_attributes(_params)
    if @paper_process.persisted? && @paper_process.valid?
      session[:paper_process]     = nil
      session[:new_paper_process] = @paper_process.dup
      session[:old_paper_process] = @paper_process.reload
      flash[:notice] = 'Existe déjà.'
    elsif @paper_process.save
      session[:paper_process]     = nil
      @paper_process.user         = User.find_by_code @paper_process.customer_code
      @paper_process.organization = @paper_process.user.try(:organization)
      @paper_process.save
      flash[:success] = 'Créé avec succès.'
    else
      session[:paper_process] = @paper_process
      flash[:error] = 'Donnée(s) invalide(s).'
    end
    redirect_to kits_path
  end

  def overwrite
    paper_process = PaperProcess.find params[:id]
    paper_process.update_attributes(paper_process_count_params)
    reset_waiting_paper_process
    flash[:success] = 'Remplacé avec succès.'
    redirect_to kits_path
  end

  def cancel
    reset_waiting_paper_process
    redirect_to kits_path
  end

private

  def paper_process_params
    params.require(:paper_process).permit(
      :tracking_number,
      :customer_code,
      :journals_count,
      :periods_count
    )
  end

  def paper_process_count_params
    params.require(:paper_process).permit(:journals_count, :periods_count)
  end

  def reset_waiting_paper_process
    session[:old_paper_process] = nil
    session[:new_paper_process] = nil
    session[:paper_process]     = nil
  end
end
