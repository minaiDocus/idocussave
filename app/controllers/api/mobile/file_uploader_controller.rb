class Api::Mobile::FileUploaderController < MobileApiController
  include DocumentsHelper

  respond_to :json

  def load_file_upload_users
    render json: { userList: file_upload_users_list.map(&:code) }, status: 200
  end

  def load_file_upload_params
    render json: { data: file_upload_params_mobile }, status: 200
  end

  def load_user_analytics
    user = User.find params[:user_id]
    result = {}
    if user && user.organization.ibiza.try(:configured?) && user.ibiza_id.present? && user.options.compta_analysis_activated?
      result = IbizaAnalytic.new(user.ibiza_id, user.organization.ibiza.access_token).list
    end
    render json: { data: result.to_json.to_s }, status: 200
  end

  def create
    data = nil

    if params[:file_code].present?
      customer = accounts.active.find_by_code(params[:file_code])
    else
      customer = @user
    end

    errors = []
    if customer.try(:options).try(:is_upload_authorized)
      params[:files].each do |file|
        uploaded_document = UploadedDocument.new(
          file.tempfile,
          file.original_filename,
          customer,
          params[:file_account_book_type],
          params[:file_prev_period_offset],
          @user,
          'mobile',
          parse_analytic_params
        )

        data = present(uploaded_document).to_json
        
        errors << { filename: file.original_filename, errors: uploaded_document.full_error_messages } unless uploaded_document.errors.empty?
      end
    else
      render json: { error: true, message: 'Accès non autorisé.' }, status: 401
      return
    end

    if errors.empty?
      render json: { success: true, message: 'Upload terminé avec succès.' }, status: 200
    else
      render json: { error: true, message: errors }, status: 200
    end
  end

  private

  def file_upload_params_mobile
    result = {}
    user = User.find params[:user_id]
    if user
      period_service = PeriodService.new user: user

      result = {
        journals: user.account_book_types.order(:name).map(&:info),
        periods:  options_for_period(period_service)
      }

      if period_service.prev_expires_at
        result[:message] = {
          period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
          date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
        }
      end

      result[:compta_analysis] = (user.organization.ibiza.try(:configured?) && user.ibiza_id.present? && user.options.compta_analysis_activated?) ? true : false
    end
    result
  end

  def parse_analytic_params
    return nil unless params[:file_compta_analysis]

    analytic_parsed = JSON.parse(params[:file_compta_analysis])
    analysis = {}
    analytic_parsed.each_with_index do |a, i|
      analysis[(i+1).to_s] = {name: a['section'].presence, ventilation: a['ventilation'].presence, axis1: a['axis1'].presence, axis2: a['axis2'].presence, axis3: a['axis3'].presence}
    end

    analysis.any? ? analysis : nil
  end
end
