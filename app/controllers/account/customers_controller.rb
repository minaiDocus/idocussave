# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::OrganizationController
  before_filter :load_customer, except: %w(index info new create search_by_code)
  before_filter :verify_rights, except: 'index'
  before_filter :verify_if_customer_is_active, only: %w(edit update edit_period_options update_period_options edit_knowings_options update_knowings_options edit_compta_options update_compta_options)
  before_filter :redirect_to_current_step
  before_filter :verify_if_account_can_be_closed, only: %w(account_close_confirm close_account)


  # GET /account/organizations/:organization_id/customers
  def index
    respond_to do |format|
      format.html do
        @customers = User.search_for_collection(customers, search_terms(params[:user_contains])).order(sort_column => sort_direction)

        @customers_count = @customers.count

        @customers  = @customers.page(params[:page]).per(params[:per_page])

        @periods = Period.where(user_id: @customers.pluck(:id)).where("start_at < ? AND end_at > ?", Time.now, Time.now).includes(:user, :product_option_orders)

        @groups = is_leader? ? @organization.groups : @user.groups
        @groups = @groups.order(name: :asc)
      end

      format.json do
        @customers = search(user_contains).order(sort_column => sort_direction).active
      end
    end
  end

  # GET /account/organizations/:organization_id/customers/:id
  def show
    @subscription     = @customer.subscription
    @period           = @subscription.periods.order(created_at: :desc).first
    @journals         = @customer.account_book_types.order(name: :asc)
    @pending_journals = @customer.retrievers.where(journal_id: nil).where.not(journal_name: [nil]).distinct(:journal_name)
  end


  # GET /account/organizations/:organization_id/customers/info
  def info
  end


  # GET /account/organizations/:organization_id/customers/new
  def new
    @customer = User.new(code: "#{@organization.code}%")
    @customer.options = UserOptions.new
  end


  # POST /account/organizations/:organization_id/customers
  def create
    @customer = CreateCustomerService.new(@organization, @user, user_params, current_user, request).execute

    if @customer.persisted?
      next_configuration_step
    else
      render :new
    end
  end


  # GET /account/organizations/:organization_id/customers/:id/edit
  def edit
  end


  # PUT /account/organizations/:organization_id/customers/:id
  def update
    @customer.is_group_required = !is_leader?

    if UpdateCustomerService.new(@customer, user_params).execute
      flash[:success] = 'Modifié avec succès'

      redirect_to account_organization_customer_path(@organization, @customer)
    else
      render :edit
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_ibiza
  def edit_ibiza
  end


  # PUT /account/organizations/:organization_id/customers/:id/update_ibiza
  def update_ibiza
    @customer.assign_attributes(ibiza_params)

    is_ibiza_id_changed = @customer.ibiza_id_changed?

    if @customer.save
      if @customer.configured?
        if is_ibiza_id_changed && @user.ibiza_id.present?
          UpdateAccountingPlan.new(@user.id).execute
        end

        flash[:success] = 'Modifié avec succès'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'compta')
      else
        next_configuration_step
      end
    else
      flash[:error] = 'Impossible de modifier'
      render 'edit'
    end
  end


  # GET /account/organizations/:organization_id/customers/:id/edit_period_options
  def edit_period_options
  end


  # PUT /account/organizations/:organization_id/customers/:id/update_period_options
  def update_period_options
    if @customer.update(period_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'period_options')
      else
        next_configuration_step
      end
    else
      render 'edit_period_options'
    end
  end


  # GET /account/organizations/:organization_id/customers/:id/edit_knowings_options
  def edit_knowings_options
  end


  # PUT /account/organizations/:organization_id/customers/:id/update_knowings_options
  def update_knowings_options
    if @customer.update(knowings_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'ged')
      else
        next_configuration_step
      end
    else
      render 'edit_knowings_options'
    end
  end


  # GET /account/organizations/:organization_id/customers/:id/edit_compta_options
  def edit_compta_options
  end


  # PUT /account/organizations/:organization_id/customers/:id/update_compta_options
  def update_compta_options
    if @customer.update(compta_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'compta')
      else
        next_configuration_step
      end
    else
      render 'edit_compta_options'
    end
  end


  # GET /account/organizations/:organization_id/customers/:id/account_close_confirm
  def account_close_confirm
  end


  # PUT /account/organizations/:organization_id/customers/:id/close_account
  def close_account
    StopSubscriptionService.new(@customer, params[:close_now]).execute

    flash[:success] = 'Dossier clôturé avec succès.'

    redirect_to account_organization_customer_path(@organization, @customer)
  end


  # /account/organizations/:organization_id/customers/:id/account_reopen_confirm
  def account_reopen_confirm
  end


  # PUT /account/organizations/:organization_id/customers/:id/reopen_account(.:format)
  def reopen_account
    ReopenSubscription.new(@customer, @user, request).execute
    flash[:success] = 'Dossier réouvert avec succès.'
    redirect_to account_organization_customer_path(@organization, @customer)
  end


  def search_by_code
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = is_leader? ? @organization.customers : @user.customers
      users = users.where(code: /.*#{params[:q]}.*/i).order(code: :asc).limit(10)
      users.each do |user|
        tags << { id: user.id.to_s, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json { render json: tags.to_json, status: :ok }
    end
  end


  private


  def can_manage?
    is_leader? || @user.can_manage_customers?
  end


  def verify_rights
    authorized = true
    authorized = false unless can_manage?
    authorized = false if action_name.in?(%w(account_close_confirm close_account)) && params[:close_now] == '1' && !@user.is_admin
    authorized = false if action_name.in?(%w(info new create destroy)) && !@organization.is_active
    if action_name.in?(%w(info new create))
      authorized = false unless is_leader? || @user.groups.any?
    end
    #authorized = false if action_name.in?(%w(edit_period_options update_period_options)) && !@customer.options.is_upload_authorized

    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end


  def verify_if_account_can_be_closed
    subscription = @customer.subscription

    if subscription.is_micro_package_active && subscription.created_at > 12.months.ago && !params[:close_now]
      flash[:error] = "Ce dossier est souscrit à un forfait iDo'Micro avec un engagement minimum de un an"

      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end


  def user_params
    attributes = [
      :company,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      { group_ids: [] },
      :parent_id,
      { options_attributes: [:is_taxable, :is_pre_assignment_date_computed] }
    ]

    attributes[-1][:options_attributes] << :is_own_csv_descriptor_used if @user.is_admin

    attributes << :code if action_name == 'create'

    params.require(:user).permit(*attributes)
  end


  def ibiza_params
    params.require(:user).permit(:ibiza_id, options_attributes: [:id, :is_auto_deliver])
  end


  def period_options_params
    if current_user.is_admin
      params.require(:user).permit(
        :authd_prev_period,
        :auth_prev_period_until_day,
        :auth_prev_period_until_month
      )
    else
      params.require(:user).permit(
        :authd_prev_period,
        :auth_prev_period_until_day
      )
    end
  end


  def knowings_options_params
    params.require(:user).permit(:knowings_code, :knowings_visibility)
  end


  def compta_options_params
    params.require(:user).permit(options_attributes: [:id, :is_taxable, :is_pre_assignment_date_computed])
  end


  def load_customer
    @customer = customers.find(params[:id])
  end


  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column


  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction


  def is_max_number_of_journals_reached?
    @customer.account_book_types.count >= @customer.options.max_number_of_journals
  end
  helper_method :is_max_number_of_journals_reached?
end
