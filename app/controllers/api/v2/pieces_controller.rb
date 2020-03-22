class Api::V2::PiecesController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def get_by_name
  end

  def update
    piece = Pack::Piece.find(params[:id])

    if piece.update(piece_params)
      AccountingWorkflow::SendPieceToPreAssignment.new(piece).execute if piece.pre_assignment_state == 'supplier_recognition'

      render json: serializer.new(piece)
    else
      render json: piece.errors, status: :unprocessable_entity
    end
  end

  private

  def piece_params
    params.require(:piece).permit(:detected_third_party_id)
  end

  def serializer
    PackPieceSerializer
  end
end
