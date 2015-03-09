# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_resources

  def edit
  end

  def update
    subscription_form = SubscriptionForm.new(@subscription, @user)
    if subscription_form.submit(scan_subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'subscription')
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_resources
    @subscription = @organization.find_or_create_subscription
    @products     = Product.by_position
    @options      = @subscription.options.entries
  end

  def scan_subscription_params
    params.require(:scan_subscription).permit(:period_duration, :product)
  end
end
