# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::OrganizationController
  before_filter :load_customer, only: %w(show edit update stop_using restart_using update_ibiza)
  before_filter :verify_rights, except: 'index'
  before_filter :apply_attribute_changes, only: %w(show edit)

  def index
    respond_to do |format|
      format.html do
        @customers = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
        @periods = ::Scan::Period.where(:user_id.in => @customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
        @groups = is_leader? ? @organization.groups : @user.groups
        @groups = @groups.asc(:name).entries
      end

      format.json do
        @customers = search(user_contains).order([sort_column,sort_direction]).active
      end
    end
  end

  def show
    @subscription = @customer.find_or_create_scan_subscription
    @period = @subscription.periods.desc(:created_at).first
    @journals = @customer.requested_account_book_types.asc(:name)
  end

  def new
    @customer = User.new
  end

  def create
    @customer = CreateCustomer.new(@organization, @user, user_params).customer
    if @customer.persisted?
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_customer_path(@customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    attrs = @customer.request.attribute_changes.merge(user_params)
    if @customer.request.set_attributes(attrs, {}, @user)
      if @customer.request.status == ''
        flash[:success] = 'Modifié avec succès'
      else
        flash[:notice] = "En attente de validation de l'administrateur."
      end
      redirect_to account_organization_customer_path(@customer)
    else
      render action: 'edit'
    end
  end

  def update_ibiza
    if @customer.update_attribute(:ibiza_id, params[:user][:ibiza_id])
      flash[:success] = 'Modifié avec succès'
    else
      flash[:error] = 'Impossible de modifier'
    end
    redirect_to account_organization_customer_path(@customer)
  end

  def stop_using
    if @customer.request.set_attributes({ is_inactive: true }, {}, @user)
      if @customer.request.status == ''
        flash[:success] = 'Modifié avec succès'
      else
        flash[:notice] = "En attente de validation de l'administrateur."
      end
    end
    redirect_to account_organization_customer_path(@customer)
  end

  def restart_using
    if @customer.request.set_attributes({ is_inactive: false }, {}, @user)
      if @customer.request.status == ''
        flash[:success] = 'Modifié avec succès'
      else
        flash[:notice] = "En attente de validation de l'administrateur."
      end
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
    unless action_name.in?(%w(show update_ibiza)) && can_manage? or !action_name.in?(%w(show update_ibiza)) && can_edit?
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
    if action_name == 'create' or @customer && @customer.request.action == 'create'
      _params.merge! params.require(:user).permit(:group_ids)
    end
    _params
  end

  def load_customer
    @customer = @user.customers.find params[:id]
  end

  def apply_attribute_changes
    @customer.request.apply_attribute_changes
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