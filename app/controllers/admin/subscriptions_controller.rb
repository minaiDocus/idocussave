class Admin::SubscriptionsController < Admin::AdminController

  def index
    @subscriptions = Subscription.all.order_by([[:created_at,:desc]]).entries.paginate :page => params[:page], :per_page => 50
  end

  def edit
    
  end
end
