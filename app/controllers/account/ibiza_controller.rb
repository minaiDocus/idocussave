# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :ibiza_params, except: :refresh_users_cache

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

  def refresh_users_cache
    if @organization.ibiza.try(:is_configured?)
      @organization.ibiza.flush_users_cache
      @organization.ibiza.get_users_only_once
      flash[:success] = 'Rafraîchissement de la liste des dossiers Ibiza en cours.'
    end
    path = params[:back].present? ? params[:back] : account_organization_path
    redirect_to path
  end

private

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def ibiza_params
    params.require(:ibiza).permit(:token, :is_auto_deliver, :description, :description_separator, :piece_name_format, :piece_name_format_sep)
  end
end
