# frozen_string_literal: true

class Account::CustomerAddressesController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_address, only: %w[edit update destroy]

  # GET /account/organizations/:organization_id/customers/:customer_id/addresses
  def index
    @addresses = @customer.addresses.all
  end

  # /account/organizations/:organization_id/customers/:customer_id/addresses/new
  def new
    @address = Address.new
    @address.first_name = @customer.first_name
    @address.last_name  = @customer.last_name
  end

  # POST /account/organizations/:organization_id/customers/:customer_id/addresses
  def create
    @address = @customer.addresses.new(address_params)
    if @address.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/customers/:customer_id/addresses/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/customers/:customer_id/addresses/:id
  def update
    if @address.update(address_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    else
      render :edit
    end
  end

  # DELETE /account/organizations/:organization_id/customers/:customer_id/addresses/:id
  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    end
  end

  private

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_address
    @address = @customer.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :first_name,
      :last_name,
      :company,
      :company_number,
      :address_1,
      :address_2,
      :city,
      :zip,
      :state,
      :country,
      :building,
      :place_called_or_postal_box,
      :door_code,
      :other,
      :phone,
      :is_for_paper_return,
      :is_for_paper_set_shipping,
      :is_for_dematbox_shipping
    )
  end
end
