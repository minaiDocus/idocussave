# -*- encoding : UTF-8 -*-
class Admin::OrganizationSubscriptionsController < Admin::AdminController
  before_filter :load_organization

  layout :nil_layout

  def show
    @subscription = @organization.find_or_create_subscription
    @options = @subscription.product_option_orders.where(:group_position.gte => 1000).by_position
  end

  def edit
    @subscription = @organization.find_or_create_subscription
    @products = Product.subscribable
    @options = @subscription.product_option_orders.map { |option| option.to_a }
    @requested_options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end

  def update
    @subscription = @organization.find_or_create_subscription
    respond_to do |format|
      if @subscription.update_attributes(scan_subscription_params.merge({ force_assignment: 1 }))
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @subscription.to_json, status: :unprocessable_entity }
        format.html{ redirect_to admin_user_path(@user), error: "Impossible de modifier l'abonnement." }
      end
    end
  end

private

  def scan_subscription_params
    params.require(:scan_subscription).permit!
  end
end
