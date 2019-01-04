# -*- encoding : UTF-8 -*-
class Account::ExactOnlineController < Account::AccountController
  before_filter :load_customer, except: [:subscribe, :unsubscribe]
  before_filter :verify_rights
  before_filter :load_session_customer, only: :subscribe
  before_filter :load_unsubscribing_customer, only: :unsubscribe
  before_filter :load_exact_online
  before_filter :load_organization

  def authenticate
    session[:customer_id] = @customer.id
    redirect_to ExactOnlineSdk::Session.new(@exact_online.api_keys).get_authorize_url(subscribe_account_exact_online_url, true)
  end

  def subscribe
    success = false

    if params[:code].present?
      @exact_online.reset
      @exact_online.verifying

      if success = SetupExactOnline.new(@exact_online.id.to_s, params[:code], subscribe_account_exact_online_url).execute
        if @customer.exact_online.fully_configured?
          UpdateAccountingPlan.new(@customer).delay.execute
        end
      end
    end

    flash[:success] = 'Liaison Exact Online réussi' if success
    flash[:error] = "Echec de la liaison Exact Online" unless success

    redirect_to account_organization_customer_path(@organization, @customer, tab: 'exact_online')
  end

  def unsubscribe
    @exact_online.reset unless @exact_online.deactivated?
    flash[:success] = 'Liaison avec Exact Online supprimée.'
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'exact_online')
  end

private

  def verify_rights
    unless @user.leader? || @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_unsubscribing_customer
    @customer = params[:u].present? ? User.find(Base64.decode64(params[:u]).to_i): nil
  end

  def load_session_customer
    @customer = User.find session[:customer_id]
  end

  def load_customer
    @customer = User.find params[:customer_id]
  end

  def load_organization
    @organization = @customer.organization
  end

  def load_exact_online
    @exact_online = @customer.exact_online
    unless @exact_online && @exact_online.api_keys_present?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end
end
