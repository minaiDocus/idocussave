class Account::AnalyticsController < Account::AccountController
  before_action :load_customer
  before_action :verify_rights

  def index
    result = IbizaAnalytic.new(@customer.ibiza_id, ibiza.access_token).list
    respond_to do |format|
      format.json { render json: result.to_json, status: :ok }
    end
  end

  private

  def load_customer
    @customer = accounts.find_by(code: params[:code])
  end

  def verify_rights
    unless @customer && @customer.ibiza_id.present? && @customer.options.compta_analysis_activated? && ibiza.try(:configured?)
      respond_to do |format|
        format.json { render json: { message: 'Unauthorized' }, status: 401 }
      end
    end
  end

  def ibiza
    @ibiza ||= @customer.organization.ibiza
  end
end
