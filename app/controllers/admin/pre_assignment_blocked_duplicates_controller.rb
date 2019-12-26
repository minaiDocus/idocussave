# frozen_string_literal: true

class Admin::PreAssignmentBlockedDuplicatesController < Admin::AdminController
  # GET /admin/pre_assignment_blocked_duplicates
  def index
    @duplicates = Pack::Report::Preseizure
                  .blocked_duplicates
                  .search(search_terms(params[:duplicate_contains]))
                  .order("#{sort_real_column} #{sort_direction}")
                  .page(params[:page])
                  .per(params[:per_page])
  end

  private

  def sort_column
    if params[:sort].in? %w[created_at piece_name piece_number third_party amount date]
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_real_column
    column = sort_column
    return 'pack_pieces.name' if column == 'piece_name'
    return 'cached_amount' if column == 'amount'

    column
  end

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end
