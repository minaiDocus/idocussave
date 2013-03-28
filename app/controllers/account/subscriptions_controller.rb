# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::OrganizationController
  before_filter :load_customer, :load_subscription, :load_product
  before_filter :verify_rights

  def edit
    @options = @subscription.requested_product_option_orders.map { |option| option.to_a }
  end
  
  def update
    if @subscription.update_attributes(scan_subscription_params)
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_customer_path(@customer)
    else
      render action: 'edit'
    end
  end

private

  def scan_subscription_params
    params.require(:scan_subscription).permit(:period_duration, :requested_product)
  end

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
