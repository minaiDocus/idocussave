# frozen_string_literal: true

class Admin::JobProcessingController < Admin::AdminController
  # GET /admin/job_processing
  def index
    @jobs = JobProcessing.search(search_terms(params[:job_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def kill_job_softly
    # job_processing = JobProcessing.find params[:id]

    # $remote_lock.release_lock job_processing.name

    # job_processing.kill

    render json: { success: true }, status: :ok
  end

  def real_time_event
    @jobs = JobProcessing.search(search_terms(params[:job_contains])).order(state: :desc).last(50)

    render partial: 'real_time_event'
  end

  def launch_data_verif
    DataVerificator::DailyDataVerifierWorker.perform_async
    flash[:success] = 'Data vérificator lanché avec succès'

    redirect_to admin_job_processing_index_path
  end

  private

  def sort_column
    if params[:sort].in? %w[started_at name finished_at state]
      params[:sort]
    else
      'state'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end