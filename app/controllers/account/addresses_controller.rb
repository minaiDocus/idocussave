# -*- encoding : UTF-8 -*-
class Account::AddressesController < Account::AccountController
  layout 'inner'

  before_filter :load_address, only: %w(edit update destroy)

  def index
    @addresses = @user.addresses.all
  end

  def new
    @address = Address.new
    @address.first_name = @user.first_name
    @address.last_name  = @user.last_name
  end

  def create
    @address = @user.addresses.new(address_params)
    if @address.save && @user.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_addresses_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @address.update_attributes(address_params) && @user.save
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_addresses_path
    else
      render action: 'edit'
    end
  end

  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès.'
      redirect_to account_addresses_path
    end
  end

private

  def load_address
    @address = @user.addresses.find(params[:id])
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
      :phone_mobile,
      :is_for_billing,
      :is_for_shipping
    )
  end
end
