# -*- encoding : UTF-8 -*-
class Account::OrdersController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_customer

  def index
    @orders = @customer.orders.desc(:created_at)
  end

  def show
  end

  def new
    @order = Order.new
    @order.user = @customer
    if params[:type] == 'paper_set'
      @order.type = 'paper_set'
      time = Time.now.end_of_year
      case @customer.subscription.period_duration
      when 1
        time = time.beginning_of_month
      when 3
        time = time.beginning_of_quarter
      when 12
        time = time.beginning_of_year
      end
      @order.paper_set_end_date = time
    else
      @order.type = 'dematbox'
    end
    @order.address = Address.new
  end

  def create
    @order = Order.new(order_params)
    @order.address.is_for_an_order = true if @order.address
    if @order.dematbox? && DematboxOrder.new(@customer, @order).execute
      flash[:success] = "Votre commande de scanner iDocus'Box a été prise en compte."
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    elsif @order.paper_set? && PaperSetOrder.new(@customer, @order).execute
      flash[:success] = 'Votre commande de Kit papier a été prise en compte.'
      redirect_to account_organization_customer_orders_path(@organization, @customer)
    else
      render action: :new
    end
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end

  def order_params
    case params[:order].try(:[], :type)
    when 'dematbox'
      dematbox_order_params
    when 'paper_set'
      paper_set_order_params
    end
  end

  def dematbox_order_params
    params.require(:order).permit([
      :type,
      :dematbox_count,
      address_attributes: [
        :first_name,
        :last_name,
        :email,
        :phone,
        :company,
        :company_number,
        :address_1,
        :city,
        :zip,
        :door_code,
        :other
      ]
    ])
  end

  def paper_set_order_params
    params.require(:order).permit([
      :type,
      :paper_set_casing_size,
      :paper_set_folder_count,
      :paper_set_start_date,
      :paper_set_end_date
    ])
  end
end
