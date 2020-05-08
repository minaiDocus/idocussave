class Api::V2::PiecesController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token
  
  def get_by_name
  end

  def update
    piece = Pack::Piece.find(params[:id])

    if piece.update(piece_params)
      piece.waiting_pre_assignment if piece.pre_assignment_state == 'supplier_recognition' && piece.detected_third_party_id

      render json: serializer.new(piece)
    else
      render json: piece.errors, status: :unprocessable_entity
    end
  end

  protected
  
  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
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
