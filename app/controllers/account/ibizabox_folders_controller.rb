class Account::IbizaboxFoldersController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_rights
  before_filter :verify_if_customer_is_active

  def update
    @folder = @customer.ibizabox_folders.find params[:id]
    if (@folder.active? ? @folder.disable : @folder.enable)
      flash[:success] = "#{@folder.active? ? 'Activé' : 'Désactivé'} avec succès"
    else
      flash[:error] = "#{@folder.active? ? 'Désactivation' : 'Activation'} échouée"
    end
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza_box')
  end

  def refresh
    IbizaboxImport.update_folders(@customer)
    flash[:success] = "Mis à jour avec succès"
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza_box')
  end

  private

  def verify_rights
    is_ok = false
    if @organization.is_active
      is_ok = true if is_leader?
      is_ok = true if !is_ok && !@customer && @user.can_manage_journals?
      is_ok = true if !is_ok && @customer && @user.organization_rights_is_journals_management_authorized
    end
    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer && @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

end