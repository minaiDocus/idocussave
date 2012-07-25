# -*- encoding : UTF-8 -*-
class Admin::AddressesController < Admin::AdminController
  before_filter :load_user
  before_filter :load_instance, :except => [:index, :new, :create, :update_multiple]
  
  def index
  end
  
  def new
    @address = @user.addresses.build
  end

  def create
    @address = Address.new params[:address]
    if @address.valid?
      @user.addresses << @address
      @user.save
      
      flash[:notice] = "Créer avec succès."
      redirect_to admin_user_addresses_path(@user)
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @address.update_attributes params[:address]
      flash[:notice] = "Modifiée avec succès."
      redirect_to admin_user_addresses_path(@user)
    else
      render :action => "edit"
    end
  end

  def destroy
    @address.destroy
    flash[:notice] = "Supprimé avec succès."
    redirect_to admin_user_addresses_path(@user)
  end
  
  def update_multiple
    if params[:billing_address]
      @user.addresses.for_billing.each do |address|
        address.is_for_billing = false
      end
      
      new_billing_address = @user.addresses.find params[:billing_address]
      new_billing_address.is_for_billing = true
    end
    
    if params[:shipping_address]
      @user.addresses.for_shipping.each do |address|
        address.is_for_shipping = false
      end
      
      new_shipping_address = @user.addresses.find params[:shipping_address]
      new_shipping_address.is_for_shipping = true
    end
    
    @user.save
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_user_addresses_path(@user) }
    end
  end

  protected

  def load_user
    @user = User.find params[:user_id]
  end
  
  def load_instance
    @address = @user.addresses.find(params[:id])
  end
end
