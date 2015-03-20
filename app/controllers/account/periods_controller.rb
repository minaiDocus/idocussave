# -*- encoding : UTF-8 -*-
class Account::PeriodsController < Account::AccountController
  layout nil

  before_filter :load_period, :verify_rights

private

  def load_period
    @period = Period.find params[:id]
  end

  def verify_rights
    if @period.user != current_user and !current_user.in?(@period.user.try(:prescribers) || []) and !current_user.is_admin
      redirect_to root_path
    end
  end

public

  def show
    respond_to do |format|
      format.html { redirect_to account_reporting_path }
      format.json { render :json => PeriodPresenter.new(@period, current_user).render_json, :status => :ok }
    end
  end
end
