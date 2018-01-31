class MyCompanyFilesController < ApplicationController
  # before_action :authenticate if %w(staging sandbox production).include?(Rails.env)
  skip_before_filter :verify_authenticity_token

  def upload
    # McfDocument.create(
    #   code:          params[:IdBaseClient],
    #   journal:       params[:Type],
    #   file64:        params[:ByteResponse],
    #   control_token: params[:Token]
    # )

    path_name = File.join(Rails.root, 'files', 'testing', "#{Time.now.to_i}.blob")
    File.write path_name, Base64.encode64(params.to_s)

    respond_to do |format|
      format.json { render json: { 'Status' => 600, 'Message' => 'Success' }.to_json, status: :ok }
    end
  end

  private

  # def authenticate
  #   authenticate_or_request_with_http_basic do |name, password|
  #     Rails.application.secrets.my_company_files_api['upload_username'] == name &&
  #     Rails.application.secrets.my_company_files_api['upload_password'] == password &&
  #   end
  # end
end
