# frozen_string_literal: true

class Api::Sgi::V1::SendPieceToPreassignmentController < SgiApiController
  def piece_preassignment_needed
    @lists_pieces = []

    Pack::Piece.need_preassignment.each do |piece|
      temp_pack = TempPack.find_by_name piece.pack.name

      add_to_list_and_update_state_of piece if temp_pack.is_pre_assignment_needed? && !piece.is_a_cover
    end

    render json: { success: true, list_url: @lists_pieces }, status: 200
  end

  def download_piece
    if params[:piece_id].present?
      piece = Pack::Piece.find params[:piece_id]

      render json: { success: true, url_piece: 'https://my.idocus.com' + piece.try(:get_access_url) }, status: 200
    else
      render json: { success: true, message: 'Id pièce absent' }, status: 200
    end
  end

  def retrieve_preassignment
    #TODO: Sidekiq
    if params[:data_preassignments].present?
      list_ids_piece_update = SgiApiServices::RetrievePreAsignmentService.new(params[:data_preassignments]).execute

      render json: { success: true, list_ids_piece_update: list_ids_piece_update  }, status: 200
    else
      render json: { success: true, message: 'Data absent' }, status: 200
    end
  end

  private

  def add_to_list_and_update_state_of(piece)
    if piece.temp_document.nil? || piece.preseizures.any? || piece.is_awaiting_pre_assignment
      piece.update(pre_assignment_state: 'ready') if piece.pre_assignment_state == 'waiting'

      log_document = {
          name: "Api::Sgi::V1::SendPieceToPreassignmentController",
          error_group: "[Api-sgi-send-piece-to-pre-assignment] re-init pre assignment state",
          erreur_type: "Re-init pre assignment state",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            piece_id: piece.id,
            piece_name: piece.name,
            temp_doc: piece.temp_document.nil?,
            preseizures: piece.preseizures.any?,
            is_awaiting: piece.is_awaiting_pre_assignment,
            piece:  piece.inspect
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      return false
    end

    piece.update(is_awaiting_pre_assignment: true)
    piece.processing_pre_assignment unless piece.pre_assignment_force_processing?

    @lists_pieces << { id: piece.id, piece_name: piece.name, url_piece: 'https://my.idocus.com' + piece.try(:get_access_url) }
  end
end