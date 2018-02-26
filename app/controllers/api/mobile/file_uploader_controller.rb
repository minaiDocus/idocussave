class Api::Mobile::FileUploaderController < MobileApiController
  include DocumentsHelper

  respond_to :json

  def load_file_upload_params
    userlist = file_upload_users_list.collect do |usr|
      usr.code
    end

    render json: {userList: userlist, data: file_upload_params_mobile}, status: 200
  end

  def create
    data = nil
    if params[:file_code].present?
      customer = accounts.active.find_by_code(params[:file_code])
    else
      customer = @user
    end

    if customer.try(:options).try(:is_upload_authorized)
      params[:files].each do |file|
        uploaded_document = UploadedDocument.new(file.tempfile,
                                                 file.original_filename,
                                                 customer,
                                                 params[:file_account_book_type],
                                                 params[:file_prev_period_offset],
                                                 @user)

        data = present(uploaded_document).to_json
      end
    else
      render json: {error: true, message: 'Accès non autorisé.' }, status: 401
      return
    end

    render json: {success: true, message: "Upload terminé avec succès"}, status: 200
  end

  private

  def file_upload_params_mobile
    result = {}

    file_upload_users_list.each do |user|
      period_service = PeriodService.new user: user

      hsh = {
        journals: user.account_book_types.order(name: :asc).map do |j|
          j.name + ' ' + j.description
        end,
        periods:  options_for_period(period_service)
      }

      if period_service.prev_expires_at
        hsh[:message] = {
          period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
          date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
        }
      end

      result[user.code] = hsh
    end

    result
  end
end
