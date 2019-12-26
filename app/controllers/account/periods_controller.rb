# frozen_string_literal: true

class Account::PeriodsController < Account::AccountController
  layout false

  before_action :load_period, :verify_rights

  # GET /account/periods
  def show
    respond_to do |format|
      format.html { redirect_to account_reporting_path }
      format.json { render json: PeriodPresenter.new(@period, current_user).render_json, status: :ok }
    end
  end

  private

  def load_period
    @period = Period.find(params[:id])
  end

  def verify_rights
    unless @period.user.in?(accounts)
      respond_to do |format|
        format.html do
          flash[:error] = t('authorization.unessessary_rights')
          redirect_to account_reporting_path
        end
        format.json { render plain: 'Unauthorized', status: :unauthorized }
      end
    end
  end
end
