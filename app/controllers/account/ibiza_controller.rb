# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::OrganizationController
  before_filter :verify_rights, except: :refresh_users_cache

  def create
    @ibiza = Ibiza.new(ibiza_params)
    @ibiza.organization = @organization
    if @ibiza.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render 'edit'
    end
  end

  def edit
    @ibiza = @organization.ibiza
  end

  def update
    if @organization.ibiza.update(ibiza_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render 'edit'
    end
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
    params.require(:ibiza).permit(:token, :is_auto_deliver, :description_separator, :piece_name_format_sep).tap do |whitelist|
      whitelist[:description]       = params[:ibiza][:description].permit!
      whitelist[:piece_name_format] = params[:ibiza][:piece_name_format].permit!
    end
  end
end
