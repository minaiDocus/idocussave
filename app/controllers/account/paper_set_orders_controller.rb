# -*- encoding : UTF-8 -*-
class Account::PaperSetOrdersController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_order_and_customer, only: %w(edit update destroy)
  before_filter :verify_if_customer_can_order_paper_sets, only: %w(edit update)
  before_filter :verify_editability, only: %w(edit update destroy)

  # GET /account/organizations/:organization_id/paper_set_orders
  def index
    @orders = @organization.orders.paper_sets.where(user_id: customer_ids)
    @orders = Order.search_for_collection(@orders, search_terms(params[:order_contains]))
    @orders_count = @orders.count
    @orders = @orders.joins(:user).select("orders.*, users.code as user_code, users.company as company, users.id as user_id").order("#{sort_column} #{sort_direction}").page(params[:page]).per(params[:per_page])
  end

  # GET /account/organizations/:organization_id/paper_set_orders/new?template=
  def new
    template                      = @organization.orders.paper_sets.find params[:template]
    @order                        = Order.new
    @customer                     = template.user
    @order.user                   = @customer

    verify_if_customer_can_order_paper_sets

    @order.paper_set_casing_size  = template.paper_set_casing_size
    @order.paper_set_folder_count = @customer.options.max_number_of_journals
    @order.address                = @customer.paper_set_shipping_address.try(:dup) || Address.new
    @order.paper_return_address   = @customer.paper_return_address.try(:dup) || Address.new
    @order.paper_set_annual_end_date
  end


  # POST /account/organizations/:organization_id/paper_set_orders/create
  def create
    @order                  = Order.new(order_params)
    @order.type             = 'paper_set'
    @customer               = @organization.customers.find(params[:order][:user_id])
    if OrderPaperSet.new(@customer, @order).execute
      copy_back_paper_return_address
      flash[:success] = 'Votre commande de Kit envoi courrier a été prise en compte.'
      redirect_to account_organization_paper_set_orders_path(@organization)
    else
      render :new
    end
  end


  # GET /account/organizations/:organization_id/paper_set_orders/:id
  def edit
    @order.address                    ||= @customer.paper_set_shipping_address.try(:dup)
    @order.paper_return_address       ||= @customer.paper_return_address.try(:dup)
    @order.build_address              if @order.address.nil?
    @order.build_paper_return_address if @order.paper_return_address.nil?
  end


  # PUT /account/organizations/:organization_id/paper_set_orders/:id
  def update
    if @order.update(order_params)
      copy_back_paper_return_address
      OrderPaperSet.new(@customer, @order, true).execute
      flash[:success] = 'Votre commande a été modifiée avec succès.'
      redirect_to account_organization_paper_set_orders_path(@organization)
    else
      render :edit
    end
  end


  # DELETE /account/organizations/:organization_id/paper_set_orders/:id
  def destroy
    DestroyOrder.new(@order).execute
    flash[:success] = "Votre commande de Kit envoi courrier d'un montant de #{format_price_00(@order.price_in_cents_wo_vat)}€ HT, a été annulée."
    redirect_to account_organization_paper_set_orders_path(@organization)
  end

  def select_for_orders
    @customers = customers.active.joins(:subscription).where("is_mail_package_active = ? or is_annual_package_active = ?", true, true)
  end

  def order_multiple
    if params[:customer_ids].present?
      customers = @organization.customers.where(id: params[:customer_ids])
      @orders = customers.map do |customer|
        Order.new(user: customer, type: 'paper_set')
      end
    else
      flash[:notice] = 'Veuillez sélectionner les clients concernés'
      redirect_to select_for_orders_account_organization_paper_set_orders_path(@organization)
    end
  end

  def create_multiple
    @orders = []
    if params[:orders].any?
      params[:orders].each do |param_order|
        order_attributes       = param_order.permit(:user_id, :paper_set_casing_size, :paper_set_folder_count, :paper_set_start_date, :paper_set_end_date)
        order                  = Order.new(order_attributes)
        order.type             = 'paper_set'
        order.address_required = false
        @orders << order unless OrderPaperSet.new(order.user, order).execute
      end
    end
    if @orders.any?
      flash.now[:error] = "Les commandes ci-dessous n'ont pas été validées"
      render :order_multiple
    else
      flash[:success] = 'Vos commandes de Kit envoi courrier ont été prises en comptes'
      redirect_to account_organization_paper_set_orders_path(@organization)
    end
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column


  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def load_order_and_customer
    @order    = @organization.orders.paper_sets.find params[:id]
    @customer = @order.user
  end

  def can_manage?
    is_leader? || @user.can_manage_customers?
  end

  def verify_rights
    unless can_manage?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_can_order_paper_sets
    authorized = true
    authorized = false unless @customer.active?
    authorized = false unless @customer.subscription.is_mail_package_active || @customer.subscription.is_annual_package_active
    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_paper_set_orders_path(@organization)
    end
  end

  def verify_editability
    if (Time.now > @order.created_at + 24.hours) || !@order.pending?
      flash[:error] = "Cette action n'est plus valide."
      redirect_to account_organization_paper_set_orders_path(@organization)
    end
  end

  def order_params
    attributes = [
      :user_id,
      :paper_set_casing_size,
      :paper_set_folder_count,
      :paper_set_start_date,
      :paper_set_end_date,
      address_attributes: address_attributes,
      paper_return_address_attributes: address_attributes
    ]

    attributes << :type if action_name.in?(%w(new create))
    params.require(:order).permit(*attributes)
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
      :place_called_or_postal_box,
      :door_code,
      :other
    ]
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