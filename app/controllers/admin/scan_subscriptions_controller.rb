# -*- encoding : UTF-8 -*-
class Admin::ScanSubscriptionsController < Admin::AdminController
  before_filter :load_user

  layout :nil_layout

  def show
    if @user.is_active?
      @subscription = @user.find_or_create_scan_subscription
      @period = @subscription.periods.desc(:created_at).first
    else
      @period = nil
    end
  end

  def edit
    if @user.is_active?
      @subscription = @user.find_or_create_scan_subscription
      @products = Product.subscribable
      @options = @subscription.product_option_orders.map { |option| option.to_a }
      @requested_options = @subscription.requested_product_option_orders.map { |option| option.to_a }
    else
      @subscription = nil
    end
  end

  def update
    @subscription = @user.find_or_create_scan_subscription
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

  def load_user
    @user = User.find params[:user_id]
  end
end
