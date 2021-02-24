# frozen_string_literal: true

class MyCompanyFilesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def upload
    if valid_params?
      mcf_document = McfDocument.create_or_initialize_with(
        code: params[:IdBaseClient],
        journal: params[:Type].upcase,
        file64: params[:ByteResponse],
        original_file_name: params[:Name],
        access_token: params[:Token]
      )

      if !mcf_document.persisted?
        log_document = {
          subject: "[MyCompanyFilesController] mcf document not persisted",
          name: "MyCompanyFilesController",
          error_group: "[my-company-files-controller] mcf document not persisted",
          erreur_type: "[MCF] - Document not persisted",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            code: params[:IdBaseClient],
            journal: params[:Type].upcase,
            original_file_name: params[:Name],
            access_token: params[:Token]
          }
        }

        begin
          ErrorScriptMailer.error_notification(log_document, { attachements: [{name: params[:Name], file: StringIO.open(Base64.decode64(params[:ByteResponse]))}] }).deliver
        rescue
          ErrorScriptMailer.error_notification(log_document).deliver
        end
      end

      respond_to do |format|
        format.json { render json: { 'Status' => 600, 'Message' => 'Success' }.to_json, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: { 'Status' => @error[:status], 'Message' => @error[:message] }.to_json, status: :ok }
      end
    end
  end

  private

  def valid_params?
    return false unless valid_params_presence?
    return false unless valid_ged_sender?
    return false unless valid_user_code?
    return false unless valid_byte_response?

    true
  end

  def valid_params_presence?
    %i[Token Type Name IdBaseClient ByteResponse Ged].each_with_object(params) do |key, obj|
      unless obj[key].present?
        @error = { status: 406, message: 'Invalid parameters sent' }
        return false
      end
    end
    true
  end

  def valid_ged_sender?
    @error = { status: 602, message: 'Ged sender unknown' }

    params[:Ged].upcase == 'MCF'
  end

  def valid_user_code?
    @error = { status: 603, message: 'Client (IdBaseClient) not registered' }

    User.find_by_code(params[:IdBaseClient]).nil? ? false : true
  end

  def valid_byte_response?
    @error = { status: 604, message: 'Invalid ByteResponse parameter, must be a base64 bytecode string' }

    params[:ByteResponse].is_a?(String) ? true : false
  end
end
