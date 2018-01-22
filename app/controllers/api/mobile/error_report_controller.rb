class Api::Mobile::ErrorReportController < MobileApiController
  skip_before_filter :authenticate_mobile_user

  respond_to :json

  def send_error_report
    #sending mail to developpers
    data_report = {
                    title:      params[:error] || "Erreur App mobile",
                    user_id:    params[:user_id],
                    user_token: params[:user_token],
                    platform:   params[:platform],
                    report:     params[:report]
                  }
    MobileReportMailer.report(params[:error], data_report).deliver_now

    render json: {success: true}, status: 200
  end
end