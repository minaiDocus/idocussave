class Account::Documents::SubscriptionsController < Account::AccountController
  layout "inner", :only => %w(index show)
  
  def index
    @user = nil
    if params[:email] && current_user.is_admin
      @user = User.find_by_email(params[:email])
      flash[:notice] = "User unknow : #{params[:email]}" unless @user
    end
    if @user.nil?
      @user = current_user
    end
    @prescriber = @user.prescriber ? @user.prescriber : @user
    @year = !params[:year].blank? ? params[:year].to_i : Time.now.year
    @clients = @user.clients
    @subscriptions = @user.scan_subscription_reports
  end
  
  def show
    
  end
  
  def period
    
  end
end