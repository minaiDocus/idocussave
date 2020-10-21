# frozen_string_literal: true

class Account::IbizaboxFoldersController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_rights
  before_action :verify_if_customer_is_active

  def update
    @folder = @customer.ibizabox_folders.find params[:id]
    if @folder.active? ? @folder.disable : @folder.enable
      flash[:success] = "#{@folder.active? ? 'Activé' : 'Désactivé'} avec succès"
    else
      flash[:error] = "#{@folder.active? ? 'Désactivation' : 'Activation'} échouée"
    end
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza_box')
  end

  def refresh
    FileImport::Ibizabox.update_folders(@customer)
    flash[:success] = 'Mise à jour avec succès'
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza_box')
  end

  private

  def verify_rights
    is_ok = false
    if @organization.is_active
      is_ok = true if @user.leader?
      is_ok = true if !is_ok && !@customer && @user.manage_journals
      is_ok = true if !is_ok && @customer && @user.manage_customer_journals
    end
    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer&.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end
end
