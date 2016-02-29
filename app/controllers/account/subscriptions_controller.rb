# -*- encoding : UTF-8 -*-
class Account::SubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :redirect_to_current_step
  before_filter :load_subscription

  def edit
    @subscription.downgrade
  end

  def update
    subscription_form = SubscriptionForm.new(@subscription, @user, request)
    if subscription_form.submit(params[:subscription])
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
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
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
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end
end
