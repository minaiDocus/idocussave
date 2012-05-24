class Account::Scan::PeriodsController < Account::AccountController
  layout nil

  def show
    @period = Scan::Period.find params[:id]
    
    respond_to do |format|
      format.html {}
      format.json { render :json => @period.render_json, :status => :ok }
    end
  end
end
