# frozen_string_literal: true

class Account::PreAssignmentIgnoredController < Account::AccountController
  # GET /account/pre_assignment_ignored
  def index
    @ignored_list = Pack::Piece.pre_assignment_ignored
                               .where(user_id: account_ids)
                               .search(nil, search_terms(params[:filter_contains]))
                               .order("#{sort_column} #{sort_direction}")
                               .page(params[:page])
                               .per(params[:per_page])
  end

  def update_ignored_pieces
    if params[:confirm_ignorance].present?
      confirm_ignored_pieces
    elsif params[:force_pre_assignment].present?
      force_pre_assignment
    end

    redirect_to account_pre_assignment_ignored_path
  end

  private

  def force_pre_assignment
    pieces = Pack::Piece.pre_assignment_ignored.where(user_id: account_ids, id: params[:ignored_ids])

    if !pieces.empty?
      pieces.each(&:force_processing_pre_assignment)

      flash[:success] = 'Renvoi en pré-affectation en cours ...'
    else
      flash[:error] = 'Vous devez sélectionner au moins une pièce.'
    end
  end

  def confirm_ignored_pieces
    pieces = Pack::Piece.where(pre_assignment_state: 'ignored', user_id: account_ids, id: params[:ignored_ids])

    if !pieces.empty?
      pieces.each(&:confirm_ignorance_pre_assignment)

      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de traiter la demande.'
    end
  end

  def sort_column
    if params[:sort].in? %w[created_at name number pre_assignment_state]
      params[:sort]
    else
      'created_at'
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
