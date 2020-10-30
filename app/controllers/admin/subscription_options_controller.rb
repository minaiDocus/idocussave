# frozen_string_literal: true

class Admin::SubscriptionOptionsController < Admin::AdminController
  before_action :load_subscription_option, except: %w[new create index]

  # GET /admin/subscription_options
  def index
    @subscription_options = SubscriptionOption.by_position
  end

  # GET /admin/subscription_options/new
  def new
    @subscription_option = SubscriptionOption.new
  end

  # POST /admin/subscription_options
  def create
    @subscription_option = SubscriptionOption.new(subscription_option_params)

    if @subscription_option.save
      flash[:notice] = 'Créé avec succès.'

      redirect_to admin_subscription_options_path
    else
      render :new
    end
  end

  # GET /admin/subscription_options/:id/edit
  def edit; end

  # PUT /admin/subscription_options/:id
  def update
    if Subscription::UpdateOption.execute(@subscription_option, subscription_option_params)

      flash[:notice] = 'Modifié avec succès.'

      redirect_to admin_subscription_options_path
    else
      render :edit
    end
  end

  # DELETE /admin/subscription_options/:id
  def destroy
    if @subscription_option.destroy
      flash[:notice] = 'Supprimé avec succès.'
    else
      flash[:error] = "Impossible de supprimer l'option d'abonnement : #{@subscription_option.name}"
    end
    redirect_to admin_subscription_options_path
  end

  private

  def load_subscription_option
    @subscription_option = SubscriptionOption.find(params[:id])
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
