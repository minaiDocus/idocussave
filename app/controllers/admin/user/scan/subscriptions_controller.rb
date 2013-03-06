# -*- encoding : UTF-8 -*-
class Admin::Scan::SubscriptionsController < Admin::AdminController
  before_filter :load_resource

  layout :nil_layout

  def show
    if (@user && @user.is_active?) || @organization
      if @organization
        @subscription = @organization.find_or_create_subscription
        @options = @subscription.product_option_orders.where(:group_position.gte => 1000).by_position
      else
        @subscription = @user.find_or_create_scan_subscription
        @period = @subscription.periods.desc(:created_at).first
      end
    else
      @period = nil
    end
  end

  def edit
    if (@user && @user.is_active?) || @organization
      if @organization
        @subscription = @organization.find_or_create_subscription
      else
        @subscription = @user.find_or_create_scan_subscription
      end
      @products = Product.subscribable
      @options = @subscription.product_option_orders.map { |option| option.to_a }
      @requested_options = @subscription.requested_product_option_orders.map { |option| option.to_a }
    else
      @subscription = nil
    end
  end

  def update
    if @organization
      @subscription = @organization.find_or_create_subscription
    else
      @subscription = @user.find_or_create_scan_subscription
    end
    respond_to do |format|
      if @subscription.update_attributes params[:scan_subscription]
        @user.set_request_type!
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @subscription.to_json, status: :unprocessable_entity }
        format.html{ redirect_to admin_user_path(@user), error: "Impossible de modifier l'abonnement." }
      end
    end
  end

private

  def load_resource
    if params[:user_id]
      @user = User.find params[:user_id]
    else
      @organization = Organization.find_by_slug params[:organization_id]
      raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:organization_id]) unless @organization
      @organization
    end
  end
end
