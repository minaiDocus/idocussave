# -*- encoding : UTF-8 -*-
class Account::ExactOnlineController < Account::OrganizationController
  skip_filter   :load_organization, only: [:subscribe, :unsubscribe]
  before_filter :verify_rights
  before_filter :load_session_organization, only: :subscribe
  before_filter :load_unsubscribing_organization, only: :unsubscribe
  before_filter :load_exact_online, except: :authenticate

  def authenticate
    session[:organization_id] = @organization.id
    redirect_to ExactOnlineSdk::Session.new.get_authorize_url(subscribe_account_exact_online_url, true)
  end

  def subscribe
    if params[:code].present?
      @exact_online.verifying
      # TODO use delay
      SetupExactOnline.new(@exact_online.id.to_s, params[:code], subscribe_account_exact_online_url).execute
      flash[:success] = 'Vérification en cours...'
    else
      flash[:error] = "Configuration d'Exact annulée."
    end
    redirect_to account_organization_path(@organization, tab: 'exact')
  end

  def unsubscribe
    @exact_online.reset unless @exact_online.deactivated?
    flash[:success] = 'Liaison avec Exact supprimée.'
    redirect_to account_organization_path(@organization, tab: 'exact')
  end

private

  def verify_rights
    unless @user.leader? || @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def load_unsubscribing_organization
    @organization = params[:o].present? ? Organization.find(Base64.decode64(params[:o]).to_i): nil
  end

  def load_session_organization
    @organization = Organization.find session[:organization_id]
  end

  def load_exact_online
    @exact_online = @organization.exact_online
    unless @exact_online
      @exact_online = ExactOnline.new
      @exact_online.organization = @organization
      @exact_online.save
    end
  end
end
