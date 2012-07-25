# -*- encoding : UTF-8 -*-
class Admin::ScanSubscriptionsController < Admin::AdminController
  
  before_filter :load_scan_subscription, :only => %w(show edit update destroy)
  before_filter :filtered_user_ids, :only => %w(index)
  
protected
  def load_scan_subscription
    @scan_subscription = Scan::Subscription.find params[:id]
  end

public
  def index
    @scan_subscriptions = Scan::Subscription.all
    @scan_subscriptions = @scan_subscriptions.where(:number => params[:number]) if !params[:number].blank?
    @scan_subscriptions = @scan_subscriptions.any_in(:user_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    @scan_subscriptions = @scan_subscriptions.order_by(:number.desc, :created_at.desc).paginate :page => params[:page], :per_page => 50
  end
  
  def new
  	@scan_subscription = Scan::Subscription.new
  end
  
  def create
    @scan_subscription = Scan::Subscription.new params[:scan_subscription]
    if @scan_subscription.save
      flash[:notice] = "Créer avec succès."
      redirect_to admin_scan_subscriptions_path
    else
      render :action => :new
    end
  end
  
  def show
  end
  
  def edit
    @products = Product.subscribable
  end
  
  def update
    if @scan_subscription.update_attributes params[:scan_subscription]
      flash[:notice] = "Modifiée avec succès."
      redirect_to admin_scan_subscriptions_path
    else
      render :action => :edit
    end
  end
  
  def destroy
  end
end
