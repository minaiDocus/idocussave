class Tunnel::AddressesController < Tunnel::TunnelController
  before_filter :authenticate_user!
  before_filter :load_instance, :except => [:new, :create]
  
  def new
    @address = Address.new
  end

  def create
    @address = Address.new params[:address]
    if @address.valid?
      current_user.addresses << @address
      current_user.save
      
      redirect_to address_choice_tunnel_order_path
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @address.update_attributes params[:address]
      redirect_to address_choice_tunnel_order_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @address.destroy
    redirect_to address_choice_tunnel_order_path
  end

  protected

  def load_instance
    @address = current_user.addresses.find(params[:id])
  end
end
