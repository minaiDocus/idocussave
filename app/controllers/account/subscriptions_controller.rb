# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter { |c| c.load_user :@possessed_user }
  before_filter { |c| c.load_organization :@possessed_user }
  before_filter :load_customer, :load_subscription, :load_product, :except => 'index'
  before_filter :verify_write_access, :except => 'index'

  def index
    @subscription = @user.find_or_create_subscription
  end

  def edit
    @options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end
  
  def update
    # TODO sanitize params[:scan_subscription]
    if @subscription.valid?
      @subscription.update_attributes params[:scan_subscription]
      @user.set_request_type!
      flash[:notice] = "En attente de validation de l'administrateur."
      if @possessed_user == @user
        redirect_to account_organization_subscriptions_path
      else
        redirect_to account_organization_customer_path(@user)
      end
    else
      render action: :'edit'
    end
  end

private

  def load_customer
    @user = User.find params[:id]
  end

  def load_subscription
    @subscription = @user.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end
end
