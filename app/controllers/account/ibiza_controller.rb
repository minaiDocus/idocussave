# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::AccountController
  before_filter :verify_management_access, :load_user, :load_organization

  def create
    @organization.ibiza = Ibiza.new params[:ibiza]
    if @organization.ibiza.save
      flash[:success] = 'Créé avec succès.'
    else
      flash[:error] = 'Impossible de créer.'
    end
    redirect_to account_organization_path
  end

  def update
    if @organization.ibiza.update_attributes(params[:ibiza])
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier.'
    end
    redirect_to account_organization_path
  end
end