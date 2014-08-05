# -*- encoding : UTF-8 -*-
class Account::KnowingsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :verify_existant, only: %w(new create)
  before_filter :load_knowings, only: %w(edit update)

  def new
    @knowings = Knowings.new
  end

  def create
    @knowings = Knowings.new(knowings_params.merge(organization_id: @organization.id))
    if @knowings.save
      @knowings.reinit_configuration
      @knowings.verify_configuration if @knowings.active?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_path(@organization, tab: 'knowings')
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    @knowings.assign_attributes(knowings_params)
    configuration_changed = @knowings.configuration_changed?
    if @knowings.save
      if configuration_changed
        @knowings.reinit_configuration
        @knowings.verify_configuration if @knowings.active?
      end
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'knowings')
    else
      render action: :edit
    end
  end

private

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_existant
    if @organization.knowings.present?
      redirect_to account_organization_path(@organization)
    end
  end

  def load_knowings
    @knowings = @organization.knowings
  end

  def knowings_params
    _params = params.require(:knowings).permit(:username, :password, :url, :is_active, :is_third_party_included, :is_pre_assignment_state_included)
    _params.delete(:password) if _params[:password].blank?
    _params
  end
end
