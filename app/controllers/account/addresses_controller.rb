# frozen_string_literal: true

class Account::AddressesController < Account::AccountController
  before_action :verify_access
  before_action :load_address, only: %w[edit update destroy]

  # GET /account/addresses
  def index
    @addresses = @user.addresses.all
  end

  # GET /account/addresses/new
  def new
    @address = Address.new

    @address.first_name = @user.first_name
    @address.last_name  = @user.last_name
  end

  # POST /account/addresses
  def create
    @address = @user.addresses.new(address_params)
    if @address.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_addresses_path
    else
      render :new
    end
  end

  # POST /account/addresses/:address_id/edit
  def edit; end

  # PUT /account/addresses/:address_id
  def update
    if @address.update(address_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_addresses_path
    else
      render :edit
    end
  end

  # DELETE /account/addresses/:address_id
  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès.'
      redirect_to account_addresses_path
    end
  end

  private

  def verify_access
    if @user.is_prescriber
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end

  def load_address
    @address = @user.addresses.find(params[:id])
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
