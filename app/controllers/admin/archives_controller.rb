# frozen_string_literal: true

class Admin::ArchivesController < Admin::AdminController

  def budgea_users
    @budgea_users = Archive::BudgeaUser.search(search_terms(params[:archive_budgea_users_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

    render 'budgea_users'
  end

  def budgea_retrievers
    @budgea_retrievers = Archive::Retriever.search(search_terms(params[:archive_budgea_retrievers_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

    render 'budgea_retrievers'
  end

  private

  def sort_column
    if params[:sort].in? %w[deleted_date signin identifier platform exist is_updated is_deleted owner_id budgea_id id_connector state error error_message created]
      params[:sort]
    else
      'is_updated'
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
