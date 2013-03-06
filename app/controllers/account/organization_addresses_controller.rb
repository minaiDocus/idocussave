# -*- encoding : UTF-8 -*-
class Account::OrganizationAddressesController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter { |c| c.load_user :@possessed_user }
  before_filter { |c| c.load_organization :@possessed_user }
  before_filter :load_customer
  before_filter :load_address, only: %w(edit update destroy)

  def index
    @addresses = @user.addresses.all
  end

  def new
    @address = Address.new
  end

  def create
    @address = @user.addresses.new(params[:address])
    if @address.save && @user.save
      flash[:success] = "L'adresse a été créé avec succès"
      redirect_to account_organization_customer_addresses_path(@user)
    else
      flash[:error] = 'Impossible de créer cette adresse'
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @address.update_attributes(params[:address]) && @user.save
      flash[:success] = "L'adresse a été mis à jour avec succès"
      redirect_to account_organization_customer_addresses_path(@user)
    else
      flash[:error] = 'Impossible de mettre à jour cette adresse'
      render action: 'edit'
    end
  end

  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès'
      redirect_to account_organization_customer_addresses_path(@user)
    end
  end

  private

  def load_customer
    @user = @organization.customers.find params[:customer_id]
  end

  def load_address
    @address = @user.addresses.find(params[:id])
  end
end
