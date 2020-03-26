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

      filename = File.join(dir, "#{customer.code}_#{params[:files][0].original_filename}")
      FileUtils.copy params[:files][0].tempfile, filename

      final_file = filename
      corrected  = false

      if File.extname(filename).downcase == '.pdf' && !DocumentTools.modifiable?(filename)
        final_file = DocumentTools.force_correct_pdf(filename)
        corrected  = true

        log_document = {
          name: "Account::Documents::UploadsController",
          erreur_type: "File corrupted, this file force to correct",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            code: customer.code,
            customer: customer.inspect,
            params_file: params[:files][0].inspect
          }
        }

        begin
          ErrorScriptMailer.error_notification(log_document, { attachements: [{name: params[:files][0].original_filename, file: File.read(filename)}] } ).deliver
        rescue
          ErrorScriptMailer.error_notification(log_document).deliver
        end
      end

      uploaded_document = UploadedDocument.new(File.open(final_file),
                                               params[:files][0].original_filename,
                                               customer,
                                               params[:file_account_book_type],
                                               params[:file_prev_period_offset],
                                               current_user,
                                               'web',
                                               params[:analytic])

      if uploaded_document.errors.empty? || uploaded_document.errors.detect { |e| e.first == :already_exist }.present?
       FileUtils.rm filename   if !corrected
       FileUtils.rm final_file if final_file.present? && File.exist?(final_file.to_s)
      else
        log_document = {
          name: "Account::Documents::UploadsController",
          erreur_type: "Uploaded document failed",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            code: customer.code,
            customer: customer.inspect,
            params_file: params[:files][0].inspect,
            error_reason: uploaded_document.errors.inspect
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
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
