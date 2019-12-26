# frozen_string_literal: true

class Account::OrganizationAddressesController < Account::OrganizationController
  before_action :load_address, only: %w[edit update destroy]

  # GET /account/organizations/:organization_id/addresses
  def index
    @addresses = @organization.addresses.all
  end

  # GET /account/organizations/:organization_id/addresses/new
  def new
    leader = @user.leader? ? @user : @organization.admins.first

    @address = Address.new(
      last_name: leader&.last_name,
      first_name: leader&.first_name
    )
  end

  # POST /account/organizations/:organization_id/addresses
  def create
    @address = @organization.addresses.new(address_params)

    if @address.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_addresses_path(@organization)
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/addresses/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/new
  def update
    if @address.update(address_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_addresses_path(@organization)
    else
      render :edit
    end
  end

  # DELETE /account/organizations/:organization_id/addresses/:id
  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès.'
      redirect_to account_organization_addresses_path(@organization)
    end
  end

  private

  def load_address
    @address = @organization.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :first_name,
      :last_name,
      :company,
      :address_1,
      :address_2,
      :city,
      :zip,
      :state,
      :country,
      :phone,
      :is_for_billing,
      :is_for_paper_return,
      :is_for_paper_set_shipping
    )
  end
end
