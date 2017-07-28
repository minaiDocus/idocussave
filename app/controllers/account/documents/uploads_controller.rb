# -*- encoding : UTF-8 -*-
class Account::Documents::UploadsController < Account::AccountController
  def create
    data = nil

    if @user.documents_collaborator?
      customer = accounts.active.find_by_code(params[:file_code])
    else
      customer = @user
    end

    if customer.options.is_upload_authorized
      uploaded_document = UploadedDocument.new(params[:files][0].tempfile,
                                               params[:files][0].original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user)

      data = present(uploaded_document).to_json
    else
      data = [{ name: params[:files][0].original_filename, error: 'Accès non autorisé.' }].to_json
    end

    respond_to do |format|
      format.json { render json: data }
      format.html { render json: data } # IE8 compatibility
    end
  end
end
