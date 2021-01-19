# frozen_string_literal: true

class Account::OrdersController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_rights
  before_action :redirect_to_current_step
  before_action :load_order, only: %w[edit update destroy]
  before_action :verify_editability, only: %w[edit update destroy]

  # GET /account/organizations/:organization_id/customers/:customer_id/orders/new
  def new
    @order = Order.new
    @order.user = @customer
    @order.period_duration = @customer.subscription.period_duration
    @paper_set_prices = Order::PaperSet.paper_set_prices

    if params[:order][:type] == 'paper_set'
      @order.type = 'paper_set'
      @order.paper_set_folder_count = @customer.options.max_number_of_journals

      time = (Date.today.month < 12 ? Time.now.end_of_year : 1.month.from_now.end_of_year)

      case @customer.subscription.period_duration
      when 1
        time = time.beginning_of_month
      when 3
        time = time.beginning_of_quarter
      when 12
        time = time.beginning_of_year
      end

      @order.address              = @customer.paper_set_shipping_address.try(:dup)
      @order.paper_set_end_date   = time.to_date
      @order.paper_return_address = @customer.paper_return_address.try(:dup)
    else
      @order.type = 'dematbox'
      @order.address = @customer.dematbox_shipping_address.try(:dup)
    end

    @order.address ||= Address.new

    @order.paper_return_address ||= Address.new
  end

  # POST /account/organizations/:organization_id/customers/:customer_id/orders
  def create
    @order = Order.new(order_params)
    @paper_set_prices = Order::PaperSet.paper_set_prices

    if @order.dematbox? && Order::Dematbox.new(@customer, @order).execute
      copy_back_address

      if @customer.configured?
        flash[:success] = "La commande de #{@order.dematbox_count} scanner#{if @order.dematbox_count > 1
                                                                              's'
                                                                            end} iDocus'Box est enregistrée. Vous pouvez la modifier/annuler pendant encore 24 heures."

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'orders')
      else
        next_configuration_step
      end
    elsif @order.paper_set? && Order::PaperSet.new(@customer, @order).execute
      copy_back_address

      if @customer.configured?
        flash[:success] = 'Votre commande de Kit envoi courrier a été prise en compte.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'orders')
      else
        next_configuration_step
      end
    else
      if @order.period_duration == 3 && !@customer.configured?
        next_configuration_step
      else
        render :new
      end
    end
  end

  # GET /account/organizations/:organization_id/customers/:customer_id/orders/:id/edit
  def edit
    @paper_set_prices = Order::PaperSet.paper_set_prices
  end

  # PUT /account/organizations/:organization_id/customers/:customer_id/orders/:id
  def update
    if @order.update(order_params)
      if @order.dematbox?
        Order::Dematbox.new(@customer, @order, true).execute
      else
        Order::PaperSet.new(@customer, @order, true).execute
      end

      copy_back_address

      if @customer.configured?
        flash[:success] = 'Votre commande a été modifiée avec succès.'
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'orders')
      else
        next_configuration_step
      end
    else
      render :edit
    end
  end

  # DELETE /account/organizations/:organization_id/customers/:customer_id/orders/:id
  def destroy
    Order::Destroy.new(@order).execute

    if @order.dematbox?
      flash[:success] = "Votre commande de #{@order.dematbox_count} scanner#{if @order.dematbox_count > 1
                                                                               's'
                                                                             end} iDocus'Box d'un montant de #{format_price_00(@order.price_in_cents_wo_vat)}€ HT, a été annulée."
    else
      flash[:success] = "Votre commande de Kit envoi courrier d'un montant de #{format_price_00(@order.price_in_cents_wo_vat)}€ HT, a été annulée."
    end

    redirect_to account_organization_customer_path(@organization, @customer, tab: 'orders')
  end

  private

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  # REFACTOR
  def verify_rights
    subscription = @customer.subscription
    authorized = true
    authorized = false unless @user.leader? || @user.manage_customers
    authorized = false unless @customer.active?
    unless subscription.is_package?('mail_option') || @customer.is_dematbox_authorized || subscription.is_package?('ido_annual')
      authorized = false
    end

    if action_name.in?(%w[new create])
      if !params[:order].present?
        authorized = false
      else
        if params[:order][:type].in?(['dematbox', nil]) && !@customer.is_dematbox_authorized
          authorized = false
        end

        if params[:order][:type] == 'paper_set' && !subscription.is_package?('mail_option') && !subscription.is_package?('ido_annual')
          authorized = false
        end
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

      redirect_to account_organization_customer_path(@organization, @customer, tab: 'orders')
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
    %i[
      first_name
      last_name
      email
      phone
      company
      company_number
      address_1
      address_2
      city
      zip
      building
      place_called_or_postal_box
      door_code
      other
    ]
  end

  def dematbox_order_params
    attributes = [
      :dematbox_count,
      address_attributes: address_attributes
    ]

    attributes << :type if action_name.in?(%w[new create])

    params.require(:order).permit(*attributes)
  end

  def paper_set_order_params
    attributes = [
      :paper_set_casing_size,
      :paper_set_casing_count,
      :paper_set_folder_count,
      :paper_set_start_date,
      :paper_set_end_date,
      address_attributes: address_attributes,
      paper_return_address_attributes: address_attributes
    ]

    attributes << :type if action_name.in?(%w[new create])

    params.require(:order).permit(*attributes)
  end

  def copy_back_address
    copy_back_paper_return_address if @order.paper_set?

    address = if @order.dematbox?
                @customer.dematbox_shipping_address
              else
                @customer.paper_set_shipping_address
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

  def copy_back_paper_return_address
    address = @customer.paper_return_address

    unless address
      address = Address.new
      address.locatable           = @customer
      address.is_for_paper_return = true
    end

    address.copy(@order.paper_return_address)

    address.save
  end
end
