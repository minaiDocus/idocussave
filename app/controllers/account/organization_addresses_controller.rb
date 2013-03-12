# -*- encoding : UTF-8 -*-
class Account::OrganizationAddressesController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_rights
  before_filter :load_address, only: %w(edit update destroy)

  def index
    @addresses = @customer.addresses.all
  end

  def new
    @address = Address.new
  end

  def create
    @address = @customer.addresses.new(params[:address])
    if @address.save && @customer.save
      flash[:success] = "L'adresse a été créé avec succès"
      redirect_to account_organization_customer_addresses_path(@customer)
    else
      flash[:error] = 'Impossible de créer cette adresse'
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @address.update_attributes(params[:address]) && @customer.save
      flash[:success] = "L'adresse a été mis à jour avec succès"
      redirect_to account_organization_customer_addresses_path(@customer)
    else
      flash[:error] = 'Impossible de mettre à jour cette adresse'
      render action: 'edit'
    end
  end

  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès'
      redirect_to account_organization_customer_addresses_path(@customer)
    end
  end

  private

  def load_customer
    @customer = @organization.customers.find params[:customer_id]
  end

  def load_address
    @address = @customer.addresses.find(params[:id])
  end

  def verify_rights
    unless @organization.authorized?(@user, action_name, controller_name, @customer)
      redirect_to account_organization_path, flash: { error: t('authorization.unessessary_rights') }
    end
  end
end