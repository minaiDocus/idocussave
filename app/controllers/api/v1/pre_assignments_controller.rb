# -*- encoding : UTF-8 -*-
class Api::V1::PreAssignmentsController < ApiController
  # GET /api/v1/pre_assignments
  def index
    @pre_assignments = PreAssignmentSearch.pending(sort: 1)
  end


  # POST /api/v1/pre_assignments/update_comment
  def update_comment
    if params[:pack_name].present? && params[:comment]
      pack_ids = Pack::Piece.where(is_awaiting_pre_assignment: true).distinct(:pack_id).pluck(:pack_id)

      @pack = Pack.where(name: (params[:pack_name] + ' all'), id: pack_ids).first

      @pack.pieces.where(is_awaiting_pre_assignment: true).update_all(pre_assignment_comment: params[:comment])

      respond_to do |format|
        format.json { render json: { message: 'Updated successfully.' },       status: 200 }
        format.xml  { render xml:  '<message>Updated successfully.</message>', status: 200 }
      end
    else
      respond_with_invalid_request
    end
  end
end
