# -*- encoding : UTF-8 -*-
class Account::OrganizationAddressesController < Account::OrganizationController
  before_filter :load_address, only: %w(edit update destroy)

  def index
    @addresses = @organization.addresses.all
  end

  def new
    @address = Address.new
    @address.first_name = @organization.leader.try(:first_name)
    @address.last_name  = @organization.leader.try(:last_name)
  end

  def create
    @address = @organization.addresses.new(address_params)
    if @address.save && @organization.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_addresses_path(@organization)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @address.update(address_params) && @organization.save
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_addresses_path(@organization)
    else
      render action: 'edit'
    end
  end

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
