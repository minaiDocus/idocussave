class Api::V2::TempDocumentsController < ActionController::Base
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def create
    customer = User.find(temp_document_params[:user_id])
    journal  = customer.account_book_types.where(entry_type: temp_document_params[:accounting_type]).first

    dir = "#{Rails.root}/files/temp_pack_processor/uploaded_document/"

    FileUtils.makedirs(dir)
    FileUtils.chmod(0755, dir)

    filename = File.join(dir, "#{customer.code}_#{temp_document_params[:content_file_name]}")

    File.open(filename, 'wb') do |f|
      f.write(Base64.decode64(params[:file_base64]))
    end

    uploaded_document = UploadedDocument.new(File.open(filename),
                                            temp_document_params[:content_file_name],
                                            customer,
                                            journal.name,
                                            0,
                                            customer,
                                            temp_document_params[:api_name],
                                            nil,
                                            temp_document_params[:api_id])

    if uploaded_document
      render json: uploaded_document.to_json
    else
      render json: temp_document.errors, status: :unprocessable_entity
    end
  end

  protected

  def authenticate
    unless request.headers['Authorization'].present? && request.headers['Authorization'] == API_KEY
      head :unauthorized
    end
  end

  private

  def temp_document_params
    params.require(:temp_document).permit(:user_id, :file_base64, :accounting_type, :content_file_name, :api_name, :api_id)
  end

  def serializer
    TempDocumentSerializer
  end
end
