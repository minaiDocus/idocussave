class Api::V2::OperationsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    result = Transaction::CreateOperation.perform(operation_params.to_h["_json"])

    render json: result, status: :ok
  end

  # /api/v2/operations/not_processed/:piece_id
  def not_processed
    piece = Pack::Piece.find(params[:piece_id])

    if piece
      if piece.pre_assignment_waiting? && piece.not_processed_pre_assignment 
        response = { message: "Piece with id: #{params[:piece_id]} was marked as not processed(unprocessable piece)", success: true }
      else
        response = { message: "Piece with id: #{params[:piece_id]} can not marked piece as unprocessable (current state: #{ piece.pre_assignment_state})", success: false }
      end
    else
      response = { message: "error encountered, Piece with id: #{params[:piece_id]} not found", success: false }
    end

    render json: response, status: :ok
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def operation_params
    params.permit!
  end

  def serializer
    OperationSerializer
  end
end
