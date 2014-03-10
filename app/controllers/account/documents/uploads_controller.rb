# -*- encoding : UTF-8 -*-
class Account::Documents::UploadsController < Account::AccountController
  def create
    customer = @user.customers.active.find_by_code params[:file_code] if @user.is_prescriber
    customer ||= @user
    uploaded_document = UploadedDocument.new params[:files][0].tempfile,
                                             params[:files][0].original_filename,
                                             customer,
                                             params[:file_account_book_type],
                                             params[:file_prev_period_offset]
    tempfile_path = params[:files][0].tempfile.path
    if File.exist? tempfile_path
      File.delete tempfile_path
    end
    data = present(uploaded_document).to_json
    respond_to do |format|
      format.json{ render :json => data }
      # this one is for IE8 who is really dumb...
      format.html{ render :json => data }
    end
  end
end
