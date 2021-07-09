# frozen_string_literal: true

class Api::Sgi::V1::JefactureController < SgiApiController

    # GET /api/sgi/v1/jefacture/waiting_validation
    def waiting_validation
        data = []

        temp_preseizures = Pack::Report::TempPreseizure.waiting_validation

        if temp_preseizures.size > 0
            temp_preseizures.each do |temp_preseizure|
                data << get_infos_of(temp_preseizure)
            end

            render json: { success: true, data: data, message: '' }, status: 200
        else
            render json: { success: false, data: [], message: 'Aucune pièce à valider' }, status: 200
        end
    end

    # POST /api/sgi/v1/jefacture/pre_assigned
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


    def get_infos_of(temp_preseizure)
        temp_pack = TempPack.find_by_name temp_preseizure.piece.pack.name

        journal = temp_preseizure.piece.user.account_book_types.where(name: temp_preseizure.piece.journal).first

        {
          temp_preseizure_id: temp_preseizure.id, 
          piece_id: temp_preseizure.piece.id,
          piece_name: temp_preseizure.piece.name,
          piece_url: Domains::BASE_URL + temp_preseizure.piece.try(:get_access_url),
          compta_type: journal&.compta_type,
          pack_name: temp_pack.name,
          detected_third_party_id: (temp_preseizure.piece.detected_third_party_id.presence || 6930),
          third_party: temp_preseizure.raw_preseizure['third_party'],
          entries: temp_preseizure.raw_preseizure['entries']
        }.with_indifferent_access
    end
end
