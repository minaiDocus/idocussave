# -*- encoding : UTF-8 -*-
class Api::V1::PreAssignmentsController < ApiController
  def index
    @pre_assignments = PreAssignmentService.pending
  end

  def update_comment
    if params[:pack_name].present? && params[:comment]
      pack_ids = Pack::Piece.where(is_awaiting_pre_assignment: true).distinct(:pack_id)
      @pack = Pack.where(name: (params[:pack_name] + ' all'), :_id.in => pack_ids).first
      raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:pack_name]) unless @pack

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
