# -*- encoding : UTF-8 -*-
class Account::AddressesController < Account::AccountController
  layout 'inner'

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
      redirect_to account_addresses_path
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
      redirect_to account_addresses_path
    else
      flash[:error] = 'Impossible de mettre à jour cette adresse'
      render action: 'edit'
    end
  end
  
  def destroy
    if @address.destroy
      flash[:success] = 'Supprimé avec succès'
      redirect_to account_addresses_path
    end
  end

private

  def load_address
    @address = @user.addresses.find(params[:id])
  end

end
