# -*- encoding : UTF-8 -*-
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
  
  def new
  	@scan_subscription = Scan::Subscription.new
  end
  
  def create
    @scan_subscription = Scan::Subscription.new params[:scan_subscription]
    if @scan_subscription.save
      flash[:notice] = "Créer avec succès."
      redirect_to admin_subscriptions_path
    else
      render :action => :new
    end
  end
  
  def show
  end

  def edit
    session[:step] = @step = 1
    @products = Product.all.by_position
  end
  
  def update
    @step = session[:step]
    @step += 1
    if @step == 2
      @product = Product.find params[:product_id]
    elsif @step == 3
      @product = Product.find params[:product_id]
      @option_ids = []
      
      p  = Proc.new do |product_group, block|
        if product_group.product_subgroups
          product_group.product_subgroups.each do |product_group|
            block.call(product_group, block)
          end
        end
        if params["option_#{product_group.id}"]
          @option_ids << params["option_#{product_group.id}"]
        elsif product_group.product_options
          product_group.product_options.each do |option|
            if params["option_#{product_group.id}_#{option.id}"]
              @option_ids << params["option_#{product_group.id}_#{option.id}"]
            end
          end
        end
      end
      
      @product.product_groups.where(:product_supergroup_id => nil).entries.each do |product_group|
        p.call(product_group, p)
      end
      
      @options = @product.product_options.any_in(:_id => @option_ids).by_position.sort do |a,b|
        if a.product_group && b.product_group
          if a.product_group.position != b.product_group.position
            a.product_group.position <=> b.product_group.position
          else
            a.product_group.title <=> b.product_group.title
          end
        else
          a.position <=> b.position
        end
      end
      
      session[:option_ids] = @option_ids
    else
      @product = Product.find params[:product_id]
      @options = @product.product_options.any_in(:_id => params[:option_ids].split)
      price = 0
      price += @product.price_in_cents_w_vat
      @new_options = []
      @options.each do |option|
        quantity = 1
        if option.product_group && option.product_group.product_require
          quantity = option.product_group.product_require.product_options.any_in(:_id => @options.collect{|o| o.id}).first.quantity
        end
        price += option.price_in_cents_w_vat * quantity
        new_option = option
        new_option.price_in_cents_wo_vat *= quantity
        @new_options << new_option
      end
    
      @orders = []
      if @subscription.order
        @orders << @subscription.order
      else
        @orders << @subscription.new_order
      end
      if params[:is_parent_option] == "true"
        if @subscription.user.is_prescriber
          prescriber = @subscription.user
          if params[:is_new_option_entry] == "true"
            prescriber.clients.each do |user|
              @orders << user.find_or_create_scanning_subscription.new_order
            end
          else
            prescriber.clients.each do |user|
              if user.find_or_create_scanning_subscription.order
                @orders << user.find_or_create_scanning_subscription.order
              else
                @orders << user.find_or_create_scanning_subscription.new_order
              end
            end
          end
        end
      end
      
      @orders.each do |order|
        order.set_product_order @product, @new_options
        
        order.subscription.invalid_current_order
        order.save
        if !["paid","scanned"].include?(order.state)
          order.pay!
        end
      end
        
      flash[:notice] = "Abonnement modifié avec succès."
      redirect_to admin_subscriptions_path
    end
    session[:step] = @step
    if @step < 4
      render "edit"
    end
  end
  
  def destroy
  end
end
