# -*- encoding : UTF-8 -*-
class Account::PaperProcessesController < Account::AccountController
  before_filter :verify_rights

  # GET /account/paper_processes
  def index
    collection =  @user.is_prescriber && @user.organization ? PaperProcess.where(user_id: @user.customers.pluck(:id)) : @user.paper_processes

    @paper_processes = PaperProcess.search_for_collection_with_options_and_user(collection, search_terms(params[:paper_process_contains]), @user).order(sort_column => sort_direction).includes(:user)

    @paper_processes_count = @paper_processes.count

    @paper_processes = @paper_processes.page(params[:page]).per(params[:per_page])
  end

  private

  def verify_rights
    unless @user.is_prescriber || @user.options.is_upload_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def sort_column
    params[:sort] || 'updated_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
