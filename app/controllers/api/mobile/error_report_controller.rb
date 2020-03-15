# frozen_string_literal: true

class Api::Mobile::ErrorReportController < MobileApiController
  skip_before_action :authenticate_mobile_user
  skip_before_action :load_user_and_role
  skip_before_action :verify_suspension
  skip_before_action :verify_if_active

  respond_to :json

  def send_error_report
    data_report = {
      title: params[:error] || 'Erreur App mobile',
      user_id: params[:user_id],
      user_token: params[:user_token],
      platform: params[:platform],
      version: params[:version],
      report: params[:report]
    }

    MobileReportMailer.report(data_report).deliver

    render json: { success: true }, status: 200
  end
end
