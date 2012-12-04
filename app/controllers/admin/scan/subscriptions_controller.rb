# -*- encoding : UTF-8 -*-
class Admin::Scan::SubscriptionsController < Admin::AdminController
  before_filter :load_user

  layout :nil_layout

  private

  def load_user
    @user = User.find params[:user_id]
  end

  public

  def show
    if @user.is_active?
      if @user.is_prescriber
        @subscription = @user.find_or_create_scan_subscription
        @options = @subscription.product_option_orders.where(:group_position.gte => 1000).by_position
      else
        @period = @user.find_or_create_scan_subscription.periods.desc(:created_at).first
      end
    else
      @period = nil
    end
  end

  def edit
    if @user.is_active?
      @subscription = @user.find_or_create_scan_subscription
      @products = Product.subscribable
      @subscription.remove_not_reusable_options
      @options = @subscription.product_option_orders.map { |option| [option.title, option.price_in_cents_wo_vat] }
    else
      @subscription = nil
    end
  end

  def update
    @subscription = @user.find_or_create_scan_subscription
    respond_to do |format|
      if @subscription.update_attributes params[:scan_subscription]
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @subscription.to_json, status: :unprocessable_entity }
        format.html{ redirect_to admin_user_path(@user), error: "Impossible de modifier l'abonnement." }
      end
    end
  end
end
