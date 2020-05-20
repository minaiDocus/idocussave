# frozen_string_literal: true

class Admin::CounterErrorScriptMailerController < Admin::AdminController
  # GET /admin/counter_error_script_mailer
  def index
    @counter_error_script_mailers = CounterErrorScriptMailer.search(search_terms(params[:error_script_mailer_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def set_state
    if params[:id].present?
      id = params[:id].to_i
      counter_error_script_mailer = CounterErrorScriptMailer.find(id)

      is_enable = params[:is_enable].to_s == 'true' ? false : true if params[:is_enable].present?

      if counter_error_script_mailer.update(is_enable: is_enable)
        flash[:notice] = 'Modification d\'état avec succès'
      else
        flash[:alert] = 'Modification d\'état a échoué'
      end

      respond_to do |format|
        format.json { render json: flash.to_hash }
      end
    end
  end

  def set_counter
    if params[:id].present?
      id = params[:id].to_i
      counter_error_script_mailer = CounterErrorScriptMailer.find(id)

      counter = 0 if params[:counter].present?

      if counter_error_script_mailer.update(counter: counter)
        flash[:notice] = 'Modification de counter avec succès'
      else
        flash[:alert] = 'Modification de counter a échoué'
      end

      respond_to do |format|
        format.json { render json: flash.to_hash }
      end
    end
  end

  def error_script_mailer
    @counter_error_script_mailers = CounterErrorScriptMailer.search(search_terms(params[:error_script_mailer_contains])).order(counter: :desc).last(100)

    render partial: 'error_script_mailer'
  end

  private

  def sort_column
    if params[:sort].in? %w[error_type is_enable counter created_at updated_at]
      params[:sort]
    else
      'counter'
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