# -*- encoding : UTF-8 -*-
class Admin::SubscriptionOptionsController < Admin::AdminController
  before_filter :load_subscription_option, except: %w(new create)

  def new
    @subscription_option = SubscriptionOption.new
  end

  def create
    @subscription_option = SubscriptionOption.new subscription_option_params
    if @subscription_option.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_subscriptions_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @subscription_option.update(subscription_option_params)
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_subscriptions_path
    else
      render action: 'edit'
    end
  end

  def destroy
    if @subscription_option.destroy
      flash[:notice] = 'Supprimé avec succès.'
    else
      flash[:error] = "Impossible de supprimer l'option d'abonnement : #{@subscription_option.name}"
    end
    redirect_to admin_subscriptions_path
  end

private

  def load_subscription_option
    @subscription_option = SubscriptionOption.find params[:id]
  end

  def subscription_option_params
    params.require(:subscription_option).permit(
      :name,
      :price_in_cents_wo_vat,
      :position,
      :period_duration
    )
  end
end
