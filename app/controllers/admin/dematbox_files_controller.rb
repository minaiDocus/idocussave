# frozen_string_literal: true

class Admin::DematboxFilesController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :page_contains

  # GET /admin/dematbox_files
  def index
    @dematbox_files = TempDocument.search_dematbox_files(search_terms(params[:dematbox_file_contains])).order(sort_column => sort_direction)

    @dematbox_files_count = @dematbox_files.count

    @dematbox_files = @dematbox_files.page(params[:page]).per(params[:per_page])
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
