# -*- encoding : UTF-8 -*-
class Account::OrdersController < Account::OrganizationController
  before_filter :load_customer
  before_filter :verify_rights
  before_filter :load_order, only: %w(edit update destroy)
  before_filter :verify_editability, only: %w(edit update destroy)

  def index
    @orders = @customer.orders.desc(:created_at)
  end

  def new
    @order = Order.new
    @order.user = @customer
    @order.period_duration = @customer.subscription.period_duration
    if params[:order][:type] == 'paper_set'
      @order.type = 'paper_set'
      @order.paper_set_folder_count = @customer.options.max_number_of_journals
      time = Time.now.end_of_year
      case @customer.subscription.period_duration
      when 1
        time = time.beginning_of_month
      when 3
        time = time.beginning_of_quarter
      when 12
        time = time.beginning_of_year
      end
      @order.paper_set_end_date = time.to_date
      @order.address = @customer.paper_set_shipping_address.try(:dup)
    else
      @order.type = 'dematbox'
      @order.address = @customer.dematbox_shipping_address.try(:dup)
    end
    @order.address ||= Address.new
  end

  def create
    @order = Order.new(order_params)
    if @order.dematbox? && OrderDematbox.new(@customer, @order).execute
      copy_back_address
      flash[:success] = "La commande de #{@order.dematbox_count} scanner#{'s' if @order.dematbox_count > 1} iDocus'Box est enregistrée. Vous pouvez la modifier/annuler pendant encore 24 heures."
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    elsif @order.paper_set? && OrderPaperSet.new(@customer, @order).execute
      copy_back_address
      flash[:success] = 'Votre commande de Kit envoi courrier a été prise en compte.'
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      if @order.dematbox?
        OrderDematbox.new(@customer, @order, true).execute
      else
        OrderPaperSet.new(@customer, @order, true).execute
      end
      copy_back_address
      flash[:success] = 'Votre commande a été modifiée avec succès.'
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    else
      render action: :edit
    end
  end

  def destroy
    DestroyOrder.new(@order).execute
    if @order.dematbox?
      "Votre commande de #{@order.dematbox_count} scanner#{'s' if @order.dematbox_count > 1} iDocus'Box d'un montant de #{format_price_00(@order.price_in_cents_w_vat)}€ HT, a été annulée."
    else
      "Votre commande de Kit envoi courrier d'un montant de #{format_price_00(@order.price_in_cents_w_vat)}€ HT, a été annulée."
    end
    redirect_to account_organization_customer_orders_path(@organization, @customer)
  end

private

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end

  def verify_rights
    subscription = @customer.subscription
    authorized = true
    authorized = false unless is_leader? || @user.can_manage_customers?
    authorized = false unless subscription.is_mail_package_active || subscription.is_scan_box_package_active || subscription.is_annual_package_active
    if action_name.in?(%w(new create))
      if !params[:order].present?
        authorized = false
      else
        authorized = false if params[:order][:type].in?(['dematbox', nil]) && !subscription.is_scan_box_package_active
        authorized = false if params[:order][:type] == 'paper_set' && !subscription.is_mail_package_active && !subscription.is_annual_package_active
      end
    end
    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_order
    @order = @customer.orders.find params[:id]
  end

  def verify_editability
    if (Time.now > @order.created_at + 24.hours) || !@order.pending?
      flash[:error] = "Cette action n'est plus valide."
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    end
  end

  def order_params
    case (@order.try(:type) || params[:order].try(:[], :type))
    when 'dematbox'
      dematbox_order_params
    when 'paper_set'
      paper_set_order_params
    end
  end

  def address_attributes
    [
      :first_name,
      :last_name,
      :email,
      :phone,
      :company,
      :company_number,
      :address_1,
      :address_2,
      :city,
      :zip,
      :building,
      :door_code,
      :other
    ]
  end

  def dematbox_order_params
    attributes = [
      :dematbox_count,
      address_attributes: address_attributes
    ]
    attributes << :type if action_name.in?(%w(new create))
    params.require(:order).permit(*attributes)
  end

  def paper_set_order_params
    attributes = [
      :paper_set_casing_size,
      :paper_set_folder_count,
      :paper_set_start_date,
      :paper_set_end_date,
      address_attributes: address_attributes
    ]
    attributes << :type if action_name.in?(%w(new create))
    params.require(:order).permit(*attributes)
  end

  def copy_back_address
    if @order.dematbox?
      address = @customer.dematbox_shipping_address
    else
      address = @customer.paper_set_shipping_address
    end
    unless address
      address = Address.new
      if @order.dematbox?
        address.is_for_dematbox_shipping = true
      else
        address.is_for_paper_set_shipping = true
      end
      address.locatable = @customer
    end
    address.copy(@order.address)
    address.save
  end
end
