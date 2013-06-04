# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :ibiza_params

  def create
    @ibiza = Ibiza.new
    @ibiza.organization = @organization
    if @ibiza.update_attributes(ibiza_params)
      flash[:success] = 'Créé avec succès.'
    else
      flash[:error] = 'Impossible de créer.'
    end
    redirect_to account_organization_pre_assignments_path
  end

  def update
    if @organization.ibiza.update_attributes(ibiza_params)
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier.'
    end
    redirect_to account_organization_pre_assignments_path
  end

private

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def ibiza_params
    params.require(:ibiza).permit(:token, :is_auto_deliver, :description, :description_separator)
  end
end