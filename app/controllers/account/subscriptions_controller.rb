# frozen_string_literal: true

class Account::SubscriptionsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_subscription

  # /account/organizations/:organization_id/organization_subscription/edit
  def edit; end

  # PUT /account/organizations/:organization_id/organization_subscription
  def update
    modif_params = params[:subscription][:subscription_option]
    params[:subscription][modif_params] = true

    if Subscription::Form.new(@subscription, @user, request).submit(params[:subscription])
      @customer.update(current_configuration_step: nil) unless @customer.configured?

      if params.try(:[], :user).try(:[], :jefacture_account_id).present?
        @customer.update(jefacture_account_id: params[:user][:jefacture_account_id])
      end

      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_customer_path(@organization, @customer, tab: 'subscription')
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
