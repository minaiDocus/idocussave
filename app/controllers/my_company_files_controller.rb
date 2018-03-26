# -*- encoding : UTF-8 -*-
class MyCompanyFilesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def upload
    if valid_params?
      mcf_document =  McfDocument.create_or_initialize_with({
                                                              code:               params[:IdBaseClient],
                                                              journal:            params[:Type].upcase,
                                                              file64:             params[:ByteResponse],
                                                              original_file_name: params[:Name],
                                                              access_token:       params[:Token]
                                                            })
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

    return true
  end

  def valid_params_presence?
    [:Token, :Type, :Name, :IdBaseClient, :ByteResponse, :Ged].each_with_object(params) do |key, obj|
      unless obj[key].present?
        @error = {status: 406, message: 'Invalid parameters sent'}
        return false 
      end
    end
    return true
  end

  def valid_ged_sender?
    @error = {status: 602, message: 'Ged sender unknown'}

    return (params[:Ged].upcase != "MCF")? false : true
  end

  def valid_user_code?
    @error = {status: 603, message: 'Client (IdBaseClient) not registered'}

    return (User.find_by_code(params[:IdBaseClient]).nil?)? false : true
  end

  def valid_byte_response?
    @error = {status: 604, message: 'Invalid ByteResponse parameter, must be a base64 bytecode string'}

    return (params[:ByteResponse].is_a?(String))? true : false
  end
end
