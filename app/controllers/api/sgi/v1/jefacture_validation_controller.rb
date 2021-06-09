# frozen_string_literal: true

class Api::Sgi::V1::JefactureValidationController < SgiApiController

    # GET /api/sgi/v1/jefacture_validation/waiting_validation
    def waiting_validation
        data = []

        temp_preseizures = Pack::Report::TempPreseizure.waiting_validation

        if temp_preseizures.size > 0
            temp_preseizures.each do |temp_preseizure|
                data << { temp_preseizure_id: temp_preseizure.id, piece_infos: get_infos_of(temp_preseizure.piece), raw_preseizure: temp_preseizure.raw_preseizure }.with_indifferent_access
            end

            render json: { success: true, data: data, message: '' }, status: 200
        else
            render json: { success: false, data: [], message: 'Aucune pièce à valider' }, status: 200
        end
    end

    # POST /api/sgi/v1/jefacture_validation/pre_assigned
    def pre_assigned
        if params[:data_validated].present?
            results = SgiApiServices::AutoPreAssignedJefacturePieces.new(params[:data_validated]).execute

            success = true
            results.select {|result| success &&= result['errors'].empty?}

            render json: { success: success, results: results  }, status: 200
        else
            render json: { success: false, message: 'Paramètre data_validated manquant' }, status: 601
        end
    end

    private


    def get_infos_of(piece)
        temp_pack = TempPack.find_by_name piece.pack.name

        journal = piece.user.account_book_types.where(name: piece.journal).first

        {
            piece_id: piece.id,
            piece_name: piece.name,
            piece_url: Domains::BASE_URL + piece.try(:get_access_url),
            compta_type: journal&.compta_type,
            pack_name: temp_pack.name,
            detected_third_party_id: (piece.detected_third_party_id.presence || 6930)
        }
    end
end
