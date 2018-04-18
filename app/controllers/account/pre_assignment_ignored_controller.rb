# -*- encoding : UTF-8 -*-
class Account::PreAssignmentIgnoredController < Account::OrganizationController
  # GET /account/organizations/:organization_id/pre_assignment_ignored
  def index
    @ignored_list = Pack::Piece.pre_assignment_ignored
      .where(user_id: customer_ids)
      .order("#{sort_column} #{sort_direction}")
      .page(params[:page])
      .per(params[:per_page])
  end

  def force_pre_assignment
    pieces = Pack::Piece.pre_assignment_ignored.where(user_id: customer_ids, id: params[:ignored_ids])

    if pieces.size > 0
      pieces.each(&:force_processing_pre_assignment)
      AccountingWorkflow::SendPieceToPreAssignment.execute(pieces)

      flash[:success] = "Renvoi en pré-affectation en cours ..."
    else
      flash[:error] = 'Vous devez sélectionner au moins une pièce.'
    end

    redirect_to account_organization_pre_assignment_ignored_index_path(@organization)
  end

  private

  def sort_column
    if params[:sort].in? %w(created_at name number pre_assignment_state)
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w(asc desc)
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end
