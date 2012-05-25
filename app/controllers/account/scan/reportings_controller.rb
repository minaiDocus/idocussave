class Account::Scan::ReportingsController < Account::AccountController
  layout "inner", :only => %w(index)

  def index
    if params[:email] && current_user.is_admin
      @user = User.find_by_email(params[:email])
      flash[:notice] = "User unknow : #{params[:email]}" unless @user
    end
    @user ||= current_user
    
    @year = !params[:year].blank? ? params[:year].to_i : Time.now.year
    
    if @user.is_prescriber
      @users = @user.clients
      @subscriptions = @user.scan_subscription_reports
    else
      @users = [@user]
      @subscriptions = @user.scan_subscriptions
    end
  end
end
