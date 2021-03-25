# frozen_string_literal: true

class Account::Documents::UploadsController < Account::AccountController
  def create
    data = nil
    customer = if params[:file_code].present?
                 accounts.active.find_by_code(params[:file_code])
               else
                 @user
               end

    if customer && ( (customer.authorized_upload? && params[:files].present?) || customer.organization.specific_mission )
      uploaded_document = UploadedDocument.new(File.open(params[:files][0].tempfile),
                                               params[:files][0].original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user,
                                               'web',
                                               params[:analytic])

      data = present(uploaded_document).to_json
    else
      data = { files: [{ name: params[:files].try(:[], 0).try(:original_filename), error: 'Accès non autorisé.' }] }.to_json
    end

    respond_to do |format|
      format.json { render json: data }
      format.html { render json: data } # IE8 compatibility
    end
  end
end
