class Tunnel::OrdersController < Tunnel::TunnelController
  skip_before_filter :authenticate_user!, :only => %w(new option_choice create)
  skip_before_filter :verify_authenticity_token

  helper :paiement_cic

  def new
    @products = Product.all.by_position
  end
  
  def option_choice
    @product = Product.find params[:product_id]
  end

  def create
    if !params[:billing_address] && !params[:shipping_address]
      session[:product_id] = params[:product_id]
      session[:option_ids] = []
      require_addresses = false
      product = Product.find(params[:product_id])
      product.product_options.distinct(:group).each do |group|
        if params["option_group_#{group}"]
          session[:option_ids] << params["option_group_#{group}"]
          if  ProductOption.find(params["option_group_#{group}"]).require_addresses == true
            require_addresses = true
          end
        end
      end
      session[:require_shipping_address] = require_addresses
      require_addresses = true if product.require_billing_address
      if require_addresses
        session[:require_billing_address] = product.require_billing_address
        redirect_to address_choice_tunnel_order_url
      else
        redirect_to summary_tunnel_order_url
      end
    else
      session[:billing_address] = params[:billing_address] rescue nil
      session[:shipping_address] = params[:shipping_address] rescue nil
      redirect_to summary_tunnel_order_url
    end
  end
  
  def address_choice
    if current_user.addresses.any?
      @addresses = current_user.addresses
    else
      redirect_to new_tunnel_address_url
    end
  end
  
  def summary
    @product = Product.find session[:product_id]
    @option_ids = session[:option_ids]
    @options = @product.product_options.any_in(:_id => @option_ids).by_position
    @billing_address_id = session[:billing_address] rescue nil
    @shipping_address_id = session[:shipping_address] rescue nil
  end

  def pay
    @product = Product.find params[:product_id]
    @options = @product.product_options.any_in(:_id => params[:option_ids].split)
    price = 0
    price += @product.price_in_cents_w_vat
    @options.each do |option|
      price += option.price_in_cents_w_vat
    end
  
    order = Order.new
    ok = false
    unless current_user.use_debit_mandate
      if (current_user.balance_in_cents - price >= 0)
        ok = true
        current_user.balance_in_cents -= price
        order.payment_type = 0
      end
    else
      ok = true
      order.payment_type = 1
    end
    
    if ok
      order.set_product_order @product, @options
      if params[:billing_address_id] && params[:shipping_address_id]
        order.billing_address = current_user.addresses.find(params[:billing_address_id])
        order.shipping_address = current_user.addresses.find(params[:shipping_address_id])
      end
      order.user = current_user
      if order.save
        order.pay!
        current_user.save
        redirect_to new_tunnel_order_url
        else
        redirect_to homepages_url
      end
    else
      session[:product_id] = @product.id
      session[:option_ids] = params[:option_ids].split
      session[:billing_address] = params[:billing_address_id]
      session[:shipping_address] = params[:shipping_address_id]
      redirect_to summary_tunnel_order_url
    end
  end
  
end
