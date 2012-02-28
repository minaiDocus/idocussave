class Admin::SubscriptionsController < Admin::AdminController
  
  before_filter :load_subscription, :only => %w(show edit update destroy)
  before_filter :filtered_user_ids, :only => %w(index)

protected

  def load_subscription
    @subscription = Subscription.find params[:id]
  end

public

  def index
    @subscriptions = Subscription.all
  
    @subscriptions = @subscriptions.where(:number => params[:number]) if !params[:number].blank?
    @subscriptions = @subscriptions.any_in(:user_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    
    @subscriptions = @subscriptions.order_by(:number.desc, :created_at.desc).paginate :page => params[:page], :per_page => 50
  end
  
  def show
  end

  def edit
  end
  
  def update
    if params[:amount_in_cents]
      invoice = Invoice.create
      event = Event.new
      event.user = @subscription.user
      event.amount_in_cents = 0 - params[:amount_in_cents].to_i
      event.type_number = 1
      event.invoice = invoice
      event.title = "Prélèvement"
      event.description = "Prélèvement mensuel"
      @subscription.events << event
      if @subscription.save && @subscription.user.save && event.save && invoice.save
        @subscription.claim_money
        flash[:notice] = "Modifée avec succès."
        redirect_to admin_subscriptions_path
      else
        flash[:error] = "Une erreur est survenu."
        redirect_to edit_admin_subscription_path
      end
    end
  end
  
  def destroy
  end
end
