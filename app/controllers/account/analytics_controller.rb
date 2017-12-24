class Account::AnalyticsController < Account::AccountController
  before_action :load_customer
  before_action :verify_rights

  def index
    result = Rails.cache.fetch ['ibiza', ibiza.updated_at.to_i, @customer.id, 'analytics'], expires_in: 15.minutes do
      IbizaAnalytic.new(@customer.ibiza_id, ibiza.access_token).execute
    end

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
