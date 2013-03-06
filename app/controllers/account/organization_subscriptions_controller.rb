# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter { |c| c.load_user :@possessed_user }
  before_filter { |c| c.load_organization :@possessed_user }
  before_filter :load_subscription, :load_product, except: 'index'

  def show
    @subscription = @organization.find_or_create_subscription
  end

  def edit
    @options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end

  def update
    # TODO sanitize params[:scan_subscription]
    if @subscription.valid?
      @subscription.update_attributes params[:scan_subscription]
      # @subscription.set_request_type!
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_subscription_path
    else
      render action: :'edit'
    end
  end

private

  def load_subscription
    @subscription = @organization.find_or_create_subscription
  end

  def load_product
    @products = Product.subscribable
  end
end
