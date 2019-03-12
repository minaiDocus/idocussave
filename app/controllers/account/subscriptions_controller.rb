class Account::SubscriptionsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_subscription

  # /account/organizations/:organization_id/organization_subscription/edit
  def edit
    @subscription.downgrade
  end


  # PUT /account/organizations/:organization_id/organization_subscription
  def update
    subscription_form = SubscriptionForm.new(@subscription, @user, request)

    if subscription_form.submit(params[:subscription])
      unless @subscription.is_mail_package_active
        paper_set_orders = @customer.orders.paper_sets.pending

        if paper_set_orders.any?
          paper_set_orders.each do |order|
            DestroyOrder.new(order).execute
          end
        end
      end

      unless @subscription.is_scan_box_package_active
        dematbox_orders = @customer.orders.dematboxes.pending

        if dematbox_orders.any?
          dematbox_orders.each do |order|
            DestroyOrder.new(order).execute
          end
        end
      end

      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'subscription')
      else
        next_configuration_step
      end
    else
      flash[:error] = 'Vous devez sélectionner un forfait.'

      render :edit
    end
  end


  private

  def load_customer
    @customer = customers.find params[:customer_id]
  end


  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_subscription
    @subscription = @customer.subscription
  end


  def verify_rights
    unless @user.leader? || @user.manage_customers
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end
end
