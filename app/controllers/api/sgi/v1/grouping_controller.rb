# frozen_string_literal: true

class Api::Sgi::V1::GroupingController < SgiApiController

  # GET /api/sgi/v1/grouping/temp_document_bundle_needed
  def temp_document_bundle_needed
    render json: { success: true, temp_documents_bundle_needed: process_bundle_needed.to_json }, status: 200
  end

  # POST /api/sgi/v1/grouping/handle_piece_bundled
  def handle_piece_bundled
    group_document_response = SgiApiServices::GroupDocument.new(params[:pieces_bundled_json_content]).execute

    if group_document_response[:success] == true
      render json: { success: true, message: '' }, status: 200
    else
      render json: { success: false, message: group_document_response.to_json }, status: 601
    end  
  end

  private

  def process_bundle_needed
    temp_documents = []
    TempPack.bundle_processable.each do |temp_pack|
      temp_pack.temp_documents.bundle_needed.by_position.each do |temp_document|
        if temp_document.bundle_needed?
          data = { 
            id: temp_document.id,
            temp_pack_name: temp_document.temp_pack.name,
            temp_document_url: 'https://my.idocus.com' + temp_document.try(:get_access_url),
            delivery_type: temp_document.delivery_type,
            base_file_name: temp_document.name_with_position
          }
          
          temp_documents << data

          temp_document.bundling
        end
      end
    end

    temp_documents
  end
end
