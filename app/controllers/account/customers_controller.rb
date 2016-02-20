# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::OrganizationController
  before_filter :load_customer, except: %w(index new create search_by_code)
  before_filter :verify_rights, except: 'index'
  before_filter :verify_if_customer_is_active, only: %w(edit update edit_period_options update_period_options edit_knowings_options update_knowings_options)

  def index
    respond_to do |format|
      format.html do
        @customers = search(user_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
        @periods = Period.where(:user_id.in => @customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
        @groups = is_leader? ? @organization.groups : @user.groups
        @groups = @groups.asc(:name).entries
      end

      format.json do
        @customers = search(user_contains).order_by(sort_column => sort_direction).active
      end
    end
  end

  def show
    if @customer.subscription.configured?
      @subscription = @customer.subscription
      @period = @subscription.periods.desc(:created_at).first
      @journals = @customer.account_book_types.asc(:name)
      @pending_journals = @customer.fiduceo_retrievers.where(journal_id: nil, :journal_name.nin => [nil]).distinct(:journal_name)
    else
      redirect_to edit_account_organization_customer_subscription_path(@organization, @customer)
    end
  end

  def new
    @customer = User.new(code: "#{@organization.code}%")
    @customer.options = UserOptions.new
  end

  def create
    @customer = CreateCustomerService.new(@organization, @user, user_params, current_user, request).execute
    if @customer.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @customer.is_group_required = !is_leader?
    if UpdateCustomerService.new(@customer, user_params).execute
      flash[:success] = 'Modifié avec succès'
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      render action: 'edit'
    end
  end

  def edit_ibiza
  end

  def update_ibiza
    @customer.assign_attributes(ibiza_params)
    is_ibiza_id_changed = @customer.ibiza_id_changed?
    if @customer.save
      if is_ibiza_id_changed && @user.ibiza_id.present?
        UpdateAccountingPlan.async_execute(@user.id.to_s)
      end
      flash[:success] = 'Modifié avec succès'
    else
      flash[:error] = 'Impossible de modifier'
    end
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza')
  end

  def edit_period_options
  end

  def update_period_options
    if @customer.update(period_options_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'period_options')
    else
      render 'edit_period_options'
    end
  end

  def edit_knowings_options
  end

  def update_knowings_options
    if @customer.update(knowings_options_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'ged')
    else
      render 'edit_knowings_options'
    end
  end

  def account_close_confirm
  end

  def close_account
    StopSubscriptionService.new(@customer, params[:close_now]).execute
    flash[:success] = 'Dossier clôturé avec succès.'
    redirect_to account_organization_customer_path(@organization, @customer)
  end

  def account_reopen_confirm
  end

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
      users = users.where(code: /.*#{params[:q]}.*/i).asc(:code).limit(10)
      users.each do |user|
        tags << { id: user.id.to_s, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
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
    authorized = false if action_name.in?(%w(new create destroy)) && !@organization.is_active
    authorized = false if action_name.in?(%w(edit_period_options update_period_options)) && !@customer.options.is_upload_authorized
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
    params.require(:user).permit(:ibiza_id, options_attributes: [:is_auto_deliver])
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

  def load_customer
    @customer = customers.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:id]) unless @customer
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def user_contains
    @contains ||= {}
    if params[:user_contains] && @contains.blank?
      @contains = params[:user_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :user_contains

  def search(contains)
    users = customers
    users = users.where(:first_name => /#{Regexp.quote(contains[:first_name])}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{Regexp.quote(contains[:last_name])}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{Regexp.quote(contains[:email])}/i) unless contains[:email].blank?
    users = users.where(:company => /#{Regexp.quote(contains[:company])}/i) unless contains[:company].blank?
    users = users.where(:code => /#{Regexp.quote(contains[:code])}/i) unless contains[:code].blank?
    if is_leader? && params[:collaborator_id].present?
      ids = @organization.groups.any_in(member_ids: [params[:collaborator_id]]).map(&:_id)
      ids = ids.map { |e| e.to_s }
      users = users.any_in(group_ids: ids)
    elsif params[:group_ids].present?
      ids = is_leader? ? @organization.groups.map(&:_id) : @user['group_ids']
      ids = ids.map { |e| e.to_s }
      params[:group_ids].delete_if { |e| !e.to_s.in? ids }
      users = users.any_in(group_ids: params[:group_ids])
    end
    users = contains[:is_inactive] == '1' ? users.closed : users.active if contains[:is_inactive].present?
    users
  end

  def is_max_number_of_journals_reached?
    @customer.account_book_types.count >= @customer.options.max_number_of_journals
  end
  helper_method :is_max_number_of_journals_reached?
end
