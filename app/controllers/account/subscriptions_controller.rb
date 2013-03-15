# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::OrganizationController
  before_filter :load_customer, :load_subscription, :load_product
  before_filter :verify_rights

  def edit
    @options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end
  
  def update
    # TODO sanitize params[:scan_subscription]
    if @subscription.valid?
      @subscription.update_attributes params[:scan_subscription]
      @customer.set_request_type!
      flash[:notice] = "En attente de validation de l'administrateur."
      if @user == @customer
        redirect_to account_organization_subscriptions_path
      else
        redirect_to account_organization_customer_path(@customer)
      end
    else
      render action: :'edit'
    end
  end

private

  def load_customer
    @customer = @user.customers.find params[:id]
  end

  def load_subscription
    @subscription = @customer.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end

  def verify_rights
    unless @customer.is_editable && (is_leader? || @user.can_manage_customers?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end
end
