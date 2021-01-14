# frozen_string_literal: true

class Api::Sgi::V1::PreassignmentController < SgiApiController
  def preassignment_needed
    @lists_pieces = []
    @compta_type  = params[:compta_type]

    if (AccountBookType::TYPES_NAME - ['SPEC'] + ['TEEO']).include?(params[:compta_type])
      Pack::Piece.need_preassignment.each do |piece|
        next if piece.organization.code.upcase == "TEEO" && params[:compta_type].upcase != "TEEO"

        get_list(piece, (params[:compta_type].upcase == "TEEO" && piece.organization.code.upcase == "TEEO"))
      end

      render json: { success: true, pieces: @lists_pieces }, status: 200
    else

      render json: { success: false, error_message: "Compta type non reconnu" }, status: 200
    end
  end

  def download_piece
    if params[:piece_id].present?
      piece = Pack::Piece.find params[:piece_id]

      render json: { success: true, url_piece: Domains::BASE_URL + piece.try(:get_access_url) }, status: 200
    else
      render json: { success: false, message: 'Id pièce absent' }, status: 601
    end
  end

  def push_preassignment
    if params[:data_preassignments].present?
      results = SgiApiServices::PushPreAsignmentService.new(params[:data_preassignments]).execute

      render json: { success: true, results: results  }, status: 200
    else
      render json: { success: false, message: 'Paramètre absent' }, status: 601
    end
  end

  def update_teeo_pieces
    if params[:piece_ids].present?
      pieces = Pack::Piece.where(id: params[:piece_ids]).each(&:processed_pre_assignment)

      render json: { success: true }, status: 200
    else
      render json: { success: false, message: 'Paramètre absent' }, status: 601
    end
  end

  private

  def get_list(piece, is_teeo=false)
    temp_pack = TempPack.find_by_name piece.pack.name

    journal = piece.user.account_book_types.where(name: piece.journal).first

    compta_type_verificator = is_teeo ? true : journal.compta_type == @compta_type

    add_to_list_and_update_state_of(piece, journal.compta_type) if temp_pack && temp_pack.is_pre_assignment_needed? && !piece.is_a_cover && compta_type_verificator
  end

  def add_to_list_and_update_state_of(piece, compta_type)
    if piece.temp_document.nil? || piece.preseizures.any? || piece.is_awaiting_pre_assignment?
      piece.update(pre_assignment_state: 'ready') if piece.pre_assignment_state == 'waiting'

      log_document = {
          name: "Api::Sgi::V1::PreassignmentController",
          error_group: "[Api-sgi-pre-assignment] re-init pre assignment state",
          erreur_type: "Re-init pre assignment state",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            piece_id: piece.id,
            piece_name: piece.name,
            temp_doc: piece.temp_document.nil?,
            preseizures: piece.preseizures.any?,
            state: piece.pre_assignment_state,
            piece:  piece.inspect
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
    else
      detected_third_party_id = piece.detected_third_party_id.presence || 6930

      @lists_pieces << { id: piece.id, piece_name: piece.name, url_piece: Domains::BASE_URL + piece.try(:get_access_url), compta_type: compta_type, detected_third_party_id: detected_third_party_id, recycle: piece.pre_assignment_force_processing? }
    end
  end
end
