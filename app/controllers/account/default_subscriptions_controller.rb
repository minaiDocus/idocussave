# -*- encoding : UTF-8 -*-
class Account::DefaultSubscriptionsController < Account::OrganizationController
  before_filter :load_subscription, :load_product

  def show
  end

  def edit
    @options = @subscription.product_option_orders.map { |option| option.to_a }
  end

  def update
    if @subscription.update_attributes(scan_subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_default_subscription_path
    else
      render action: :'edit'
    end
  end

private

  def scan_subscription_params
    params.require(:scan_subscription).permit(:period_duration, :product)
  end

  def load_subscription
    @subscription = @user.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end
end
