# -*- encoding : UTF-8 -*-
class Account::Organization::DematboxController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_access
  before_filter :load_dematbox

  def create
    @dematbox.async_subscribe(params[:pairing_code])
    flash[:success] = "Configuration de iDocus'Box en cours..."
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'idocus_box')
  end

  def destroy
    @dematbox.unsubscribe
    flash[:success] = 'Supprimé avec succèss.'
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'idocus_box')
  end

private

  def verify_access
    unless @customer.is_dematbox_authorized
      flash[:success] = t('authorization.unessessary_rights')
      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end

  def load_dematbox
    @dematbox = @customer.dematbox || Dematbox.create(user_id: @customer.id)
  end
end
