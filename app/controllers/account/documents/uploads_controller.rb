# frozen_string_literal: true

class Account::Documents::UploadsController < Account::AccountController
  def create
    data = nil
    customer = if params[:file_code].present?
                 accounts.active.find_by_code(params[:file_code])
               else
                 @user
               end

    if customer.try(:options).try(:is_upload_authorized) && params[:files].present?
      dir = "#{Rails.root}/files/#{Rails.env}/temp_pack_processor/uploaded_document/"

      FileUtils.makedirs(dir)
      FileUtils.chmod(0755, dir)

      filename = File.join(dir, "#{customer.code}_#{params[:files][0].original_filename.tr(' ', '_')}")
      FileUtils.copy params[:files][0].tempfile, filename

      uploaded_document = UploadedDocument.new(File.open(filename),
                                               params[:files][0].original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user,
                                               'web',
                                               params[:analytic])

      if uploaded_document.errors.empty? || !uploaded_document.errors.detect { |e| e.first == :file_is_corrupted_or_protected }.present?
       FileUtils.rm filename
      end

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
