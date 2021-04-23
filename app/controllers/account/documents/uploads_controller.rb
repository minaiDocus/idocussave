# frozen_string_literal: true

class Account::Documents::UploadsController < Account::AccountController
  def create
    data = nil
    customer = if params[:file_code].present?
                 accounts.active.find_by_code(params[:file_code])
               else
                 @user
               end

    if params[:force]
      already_doc = Archive::AlreadyExist.find params[:id]

      file              = already_doc.path
      original_filename = params[:original_filename]
      customer          = User.find_by_code params[:user_code]

      to_upload = File.exist?(file)
    elsif params[:files].present?
      file              = params[:files][0].tempfile
      original_filename = params[:files][0].original_filename
      to_upload = true
    end

    if customer && ( (customer.authorized_upload? && to_upload) || customer.organization.specific_mission )
      uploaded_document = UploadedDocument.new(File.open(file),
                                               original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user,
                                               'web',
                                               params[:analytic],
                                               nil,
                                               params[:force])

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
