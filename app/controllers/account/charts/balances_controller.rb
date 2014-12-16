# -*- encoding : UTF-8 -*-
class Account::Charts::BalancesController < Account::AccountController
  before_filter :verify_rights
  before_filter :load_fiduceo_user_id
  before_filter :load_bank_accounts
  before_filter :load_dates

  def index
    respond_to do |format|
      format.html
      format.json do
        @balances = FiduceoBalance.new(@user.fiduceo_id, @bank_account_id, type: 'monthly', start_date: @start_date).balances
        render json: 'Service temporairement indisponible.', status: 503 unless @balances
      end
    end
  end

private

  def verify_rights
    unless @user.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_dates
    @start_date = compute_date(:start_date, Time.now.beginning_of_year.to_date)
    @end_date = compute_date(:end_date, Time.now.end_of_year.to_date)

    @start_date = 20.years.ago.beginning_of_year if @start_date.year < (Time.now.year - 20)
    @end_date = Time.now.end_of_year if @end_date.year > (Time.now.year + 1)

    if @end_date < @start_date
      @end_date = @start_date.end_of_year
    end
  end

  def compute_date(key, default_value)
    value = nil
    if params[key].present?
      if params[key].is_a? Hash
        value = "#{params[key][:year]}-#{params[key][:month]}-#{params[key][:day]}".to_date rescue default_value
      else
        value = params[key].to_date rescue default_value
      end
    else
      value = default_value
    end
    value
  end
end
