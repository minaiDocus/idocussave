# -*- encoding : UTF-8 -*-
class Account::PeriodsController < Account::AccountController
  layout nil
  
  before_filter :load_period, :verify_rights
  
private
  def load_period
    @period = ::Scan::Period.find params[:id]
  end

  def verify_rights
    if @period.user != current_user and !current_user.in?(@period.subscription.user.try(:prescribers) || []) and !current_user.is_admin
      redirect_to root_path
    end
  end

public
  def show
    respond_to do |format|
      format.html {}
      format.json { render :json => @period.render_json(current_user), :status => :ok }
    end
  end
end
