# frozen_string_literal: true

class Account::KnowingsController < Account::OrganizationController
  before_action :verify_rights
  before_action :verify_existant, only: %w[new create]
  before_action :load_knowings, only: %w[edit update]

  # GET /account/organizations/:organization_id/knowings/new
  def new
    @knowings = Knowings.new
  end

  # POST /account/organizations/:organization_id/knowings
  def create
    @knowings = Knowings.new(knowings_params.merge(organization_id: @organization.id))

    if @knowings.save
      @knowings.reinit_configuration

      @knowings.verify_configuration if @knowings.active?

      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_path(@organization, tab: 'knowings')
    else
      render :new
    end
  end

  # POST /account/organizations/:organization_id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/knowings
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
      render :edit
    end
  end

  private

  def verify_rights
    unless @user.leader?
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
    _params = params.require(:knowings).permit(:username, :password, :url, :pole_name, :is_active, :is_third_party_included, :is_pre_assignment_state_included)
    _params.delete(:password) if _params[:password].blank?
    _params
  end
end
