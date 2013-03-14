# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_filter :load_subscription, :load_product

  def show
  end

  def edit
    @options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end

  def update
    # TODO sanitize params[:scan_subscription]
    if @subscription.update_attributes params[:scan_subscription]
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_default_subscription_path
    else
      render action: :'edit'
    end
  end

private

  def load_subscription
    @subscription = @user.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end
end
