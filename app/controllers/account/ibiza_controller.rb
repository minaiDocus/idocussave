# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::OrganizationController
  before_filter :verify_rights, except: :refresh_users_cache
  before_filter :load_ibiza, except: :create

  def create
    @ibiza = Ibiza.new(ibiza_params)
    @ibiza.organization = @organization
    if @ibiza.save
      @ibiza.set_state if @ibiza.access_token.present?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render 'edit'
    end
  end

  def edit
  end

  def update
    @ibiza.assign_attributes(ibiza_params)
    is_token_changed = @ibiza.access_token_changed?
    if @ibiza.save
      if is_token_changed
        @ibiza.set_state
        @ibiza.flush_users_cache
      end
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render 'edit'
    end
  end

  def refresh_users_cache
    if @ibiza.try(:is_configured?)
      @ibiza.flush_users_cache
      @ibiza.get_users_only_once
      flash[:success] = 'Rafraîchissement de la liste des dossiers iBiza en cours.'
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

  def load_ibiza
    @ibiza = @organization.ibiza
  end

  def ibiza_params
    params.require(:ibiza).permit(:access_token, :is_auto_deliver, :description_separator, :piece_name_format_sep).tap do |whitelist|
      whitelist[:description]       = params[:ibiza][:description].permit!
      whitelist[:piece_name_format] = params[:ibiza][:piece_name_format].permit!
    end
  end
end
