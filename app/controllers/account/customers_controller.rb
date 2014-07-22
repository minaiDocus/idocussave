# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::OrganizationController
  before_filter :load_customer, only: %w(show edit update update_ibiza edit_period_options update_period_options)
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
        @customers = search(user_contains).order([sort_column,sort_direction]).active
      end
    end
  end

  def show
    @subscription = @customer.find_or_create_scan_subscription
    @period = @subscription.periods.desc(:created_at).first
    @journals = @customer.account_book_types.asc(:name)
  end

  def new
    @customer = User.new
  end

  def create
    @customer = CreateCustomer.new(@organization, @user, user_params).customer
    if @customer.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_path(@customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @customer.update_attributes(user_params)
      flash[:success] = 'Modifié avec succès'
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

  def edit_period_options
  end

  def update_period_options
    if @customer.update_attributes(period_options_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@customer)
    else
      render 'edit_period_options'
    end
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

private

  def verify_rights
    unless can_manage?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def user_params
    params.require(:user).permit(:code,
                                 :company,
                                 :first_name,
                                 :last_name,
                                 :email,
                                 :is_centralized,
                                 :group_ids,
                                 :knowings_code,
                                 :knowings_visibility)
  end

  def period_options_params
    params.require(:user).permit(:authd_prev_period,
                                 :auth_prev_period_until_day)
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
    users = users.where(:first_name => /#{Regexp.quote(contains[:first_name])}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{Regexp.quote(contains[:last_name])}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{Regexp.quote(contains[:email])}/i) unless contains[:email].blank?
    users = users.where(:company => /#{Regexp.quote(contains[:company])}/i) unless contains[:company].blank?
    users = users.where(:code => /#{Regexp.quote(contains[:code])}/i) unless contains[:code].blank?
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
