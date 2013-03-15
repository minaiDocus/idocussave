# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::OrganizationController
  before_filter :load_customer, only: %w(show edit update stop_using restart_using)
  before_filter :verify_rights, except: 'index'

  def index
    respond_to do |format|
      format.html do
        @customers = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
        @periods = ::Scan::Period.where(:user_id.in => @customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
        @groups = is_leader? ? @organization.groups : @user.groups
        @groups = @groups.asc(:name).entries
      end

      format.json do
        @customers = search(user_contains).order([sort_column,sort_direction])
      end
    end
  end

  def show
    @customer.update_request.try(:apply)
    @subscription = @customer.find_or_create_scan_subscription
    @period = @subscription.periods.desc(:created_at).first
    @journals = @customer.requested_account_book_types.unscoped.asc(:name)
  end

  def new
    @customer = User.new
  end

  def create
    @customer = User.new user_params
    @customer.is_new = true
    @customer.is_disabled = true
    @customer.request_type = User::ADDING
    @customer.set_random_password
    @customer.skip_confirmation!
    @customer.account_book_types = @organization.account_book_types.default
    @customer.requested_account_book_types = @organization.account_book_types.default
    if @customer.save
      subscription = @customer.find_or_create_scan_subscription
      new_options = @user.find_or_create_scan_subscription.product_option_orders
      @organization.members << @customer
      subscription.copy_to_options! new_options
      subscription.copy_to_requested_options! new_options
      subscription.save
      flash[:notice] = 'Demande de création envoyée.'
      redirect_to account_organization_customer_path(@customer)
    else
      flash[:error] = 'Données invalide.'
      render action: 'new'
    end
  end

  def edit
    @customer.update_request.try(:apply)
  end

  def update
    @customer.assign_attributes(user_params)
    if @customer.valid?
      if @customer.is_new
        @customer.save
      else
        @customer.update_request ||= UpdateRequest.new
        update_request = @customer.update_request
        update_request.temp_values = @customer.changes
        @customer.update_request.save
        @customer.reload
        @customer.set_request_type!
      end
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_customer_path(@customer)
    else
      render action: :edit
    end
  end

  def stop_using
    @customer.update_request.try(:apply)
    @customer.is_inactive = true
    @customer.request_changes
    if @customer.update_request.values.empty?
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_customer_path(@customer)
  end

  def restart_using
    @customer.update_request.try(:apply)
    @customer.is_inactive = false
    @customer.request_changes
    if @customer.update_request.values.empty?
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_customer_path(@customer)
  end

  def search_by_code
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = is_leader? ? @organization.members : @user.customers
      users = users.where(code: /.*#{params[:q]}.*/i).asc(:code).limit(10)
      users.each do |user|
        tags << { id: user.id, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
    end
  end

protected

  def can_manage?
    is_leader? || @user.can_manage_customers?
  end

  def can_edit?
    @customer ? (@customer.is_editable && can_manage?) : can_manage?
  end
  helper_method :can_edit?

  def cannot_edit?
    !can_edit?
  end
  helper_method :cannot_edit?

private

  def verify_rights
    unless can_edit?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def user_params
    _params = params.require(:user).permit(:code,
                                           :company,
                                           :first_name,
                                           :last_name,
                                           :email,
                                           :is_centralized)
    if action_name == 'create' or @customer && @customer.is_new
      _params.merge! params.require(:user).permit(:group_ids)
    end
    _params
  end

  def load_customer
    @customer = @user.customers.find params[:id]
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
    users = @user.customers
    users = users.where(:first_name => /#{contains[:first_name]}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{contains[:last_name]}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{contains[:email]}/i) unless contains[:email].blank?
    users = users.where(:company => /#{contains[:company]}/i) unless contains[:company].blank?
    users = users.where(:code => /#{contains[:code]}/i) unless contains[:code].blank?
    if is_leader? && params[:collaborator_id].present?
      ids = @organization.groups.any_in(collaborator_ids: [params[:collaborator_id]]).map(&:_id)
      ids = ids.map { |e| e.to_s }
      users = users.any_in(group_ids: ids)
    elsif params[:group_ids].present?
      ids = is_leader? ? @organization.groups.map(&:_id) : @user['group_ids']
      ids = ids.map { |e| e.to_s }
      params[:group_ids].delete_if { |e| !e.to_s.in? ids }
      users = users.any_in(group_ids: params[:group_ids])
    end
    users
  end
end