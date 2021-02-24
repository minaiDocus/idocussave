class Api::V2::PiecesController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token
  
  def get_by_name
  end

  def update
    piece = Pack::Piece.find(params[:id])

    if piece.update(piece_params)
      piece.reload
      piece.waiting_pre_assignment if piece.pre_assignment_state == 'supplier_recognition' && piece.detected_third_party_id

      piece.reload
      if !piece.pre_assignment_waiting?
        log_document = {
          subject: "[Api::V2::PiecesController] can't update piece state",
          name: "SupplierRecognition",
          error_group: "[SupplierRecognition] : can't update piece state",
          erreur_type: "SupplierRecognition - can't update piece state",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: { piece: piece.inspect, error: "Can't update state" }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end

      render json: serializer.new(piece)
    else
      log_document = {
        subject: "[Api::V2::PiecesController] unprocessable entity",
        name: "Unprocessable_entity",
        error_group: "[Unprocessable_entity] : unprocessable entity",
        erreur_type: "Unprocessable_entity - unprocessable entity",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: { piece: piece.inspect, error: piece.errors.inspect }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

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
