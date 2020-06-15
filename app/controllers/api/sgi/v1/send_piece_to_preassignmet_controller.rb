# frozen_string_literal: true

class Api::Sgi::V1::SendPieceToPreassignmentController < SgiApiController
  @lists_pieces = []

  def get_lists
    Pack::Piece.need_preassignment.each do |piece|
      temp_pack = TempPack.find_by_name piece.pack.name

      add_to_list_and_update_state_of piece if temp_pack.is_pre_assignment_needed? && !piece.is_a_cover 
    end

    render json: { list_url: @lists_pieces.to_json }, status: 200
  end

  def post_data(preassignments)
    #TODO: Sidekiq
    preassignments.each do |preassignment|
      SgiApiServices::RetrievePreAsignmentService.new(preassignment).execute
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