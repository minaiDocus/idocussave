# -*- encoding : UTF-8 -*-
class Account::AddressesController < ApplicationController
  before_filter :load_user
  before_filter :load_address, only: %w(edit update destroy)
  
  layout "inner"

private

  def load_user
    @user = current_user
  end

  def load_address
    @address = @user.addresses.find(params[:id])
  end
  
public

  def index
    @addresses = @user.addresses.all
  end
  
  def new
    @address = Address.new
  end
  
  def create
    @address = Address.new params[:address]
    @user.addresses << @address
    if @user.save
      flash[:success] = "L'adresse a été créer avec succès"
      redirect_to account_addresses_path
    else
      flash[:alert] = "Impossible de créer cette adresse"
      render action: "new"
    end
  end
  
  def edit
  end
  
  def update
    @address.assign_attributes(params[:address])
    if @user.save
      flash[:success] = "L'adresse a été mis à jour avec succès"
      redirect_to account_addresses_path
    else
      flash[:alert] = "Impossible de mettre à jour cette adresse"
      render action: "edit"
    end
  end
  
  def destroy
    if @address.destroy
      flash[:success] = "Supprimé avec succès"
      redirect_to account_addresses_path
    end
  end

end
