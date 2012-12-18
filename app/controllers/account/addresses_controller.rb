# -*- encoding : UTF-8 -*-
class Account::AddressesController < ApplicationController
  before_filter { |c| c.load_user :@possessed_user }
  before_filter :load_local_user
  before_filter :load_address, only: %w(edit update destroy)
  
  layout "inner"

private

  def load_local_user
    @is_manager = false
    if params[:user_id].present? && (current_user.is_prescriber or current_user.is_admin)
      begin
        @user = @possessed_user.clients.find params[:user_id]
      rescue Mongoid::Errors::DocumentNotFound
        redirect_to account_users_path
      end
      @is_manager = true
    end
    @user ||= @possessed_user
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
    @address = @user.addresses.new(params[:address])
    if @address.save && @user.save
      flash[:success] = "L'adresse a été créer avec succès"
      if @is_manager
        redirect_to account_user_addresses_path(@user)
      else
        redirect_to account_addresses_path
      end
    else
      flash[:error] = "Impossible de créer cette adresse"
      render action: "new"
    end
  end
  
  def edit
  end
  
  def update
    if @address.update_attributes(params[:address]) && @user.save
      flash[:success] = "L'adresse a été mis à jour avec succès"
      if @is_manager
        redirect_to account_user_addresses_path(@user)
      else
        redirect_to account_addresses_path
      end
    else
      flash[:error] = "Impossible de mettre à jour cette adresse"
      render action: "edit"
    end
  end
  
  def destroy
    if @address.destroy
      flash[:success] = "Supprimé avec succès"
      if @is_manager
        redirect_to account_user_addresses_path(@user)
      else
        redirect_to account_addresses_path
      end
    end
  end

end
