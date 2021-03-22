# frozen_string_literal: true

class Api::Sgi::V1::GroupingController < SgiApiController

  # GET /api/sgi/v1/grouping/bundle_needed/:delivery_type
  def bundle_needed
    render json: { success: true, bundling_documents: process_bundle_needed }, status: 200
  end

  # POST /api/sgi/v1/grouping/bundled
  def bundled
    if params[:bundled_documents].present?
      group_document_response = SgiApiServices::GroupDocument.new(params[:bundled_documents]).execute

      if group_document_response[:success] == true
        render json: { success: true, message: '' }, status: 200
      else
        render json: { success: false, message: group_document_response.to_json }, status: 601
      end
    else
      render json: { success: false, message: 'Paramètre bundled_documents manquante' }, status: 601
    end
  end

  private

  def process_bundle_needed
    temp_documents = []
    TempPack.bundle_processable.each do |temp_pack|
      temp_pack.temp_documents.by_source(params[:delivery_type]).bundle_needed.by_position.each do |temp_document|
        if temp_document.bundle_needed?
          temp_documents <<  {
            id: temp_document.id,
            temp_pack_name: temp_document.temp_pack.name,
            temp_document_url: Domains::BASE_URL + temp_document.try(:get_access_url),
            delivery_type: temp_document.delivery_type,
            base_file_name: temp_document.name_with_position
          }.with_indifferent_access
        end
      end
    end

    temp_documents
  end
end
