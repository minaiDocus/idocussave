# -*- encoding : UTF-8 -*-
class Account::CustomerAddressesController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_if_customer_is_active
  before_filter :load_address, only: %w(edit update destroy)

  def index
    @addresses = @customer.addresses.all
  end

  def new
    @address = Address.new
    @address.first_name = @customer.first_name
    @address.last_name  = @customer.last_name
  end

  def create
    @address = @customer.addresses.new(address_params)
    if @address.save && @customer.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @address.update(address_params) && @customer.save
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    else
      render action: 'edit'
    end
  end

  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès.'
      redirect_to account_organization_customer_addresses_path(@organization, @customer)
    end
  end

private

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
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
      :address_1,
      :address_2,
      :city,
      :zip,
      :state,
      :country,
      :phone,
      :phone_mobile,
      :is_for_billing,
      :is_for_shipping,
      :is_for_kit_shipping
    )
  end
end
