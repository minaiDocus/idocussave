# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter { |c| c.load_user_and_role :@possessed_user }
  before_filter { |c| c.load_organization :@possessed_user }
  before_filter :load_customer, only: %w(show edit update stop_using restart_using)
  before_filter :verify_write_access, only: %w(edit update)

  def index
    respond_to do |format|
      format.html do
        @members = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
        @periods = ::Scan::Period.where(:user_id.in => @members.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
        @groups = is_leader? ? @organization.groups : @possessed_user.groups
        @groups = @groups.asc(:name).entries
      end

      format.json do
        @members = search(user_contains).order([sort_column,sort_direction])
      end
    end
  end

  def show
    @user.update_request.try(:apply)
    @subscription = @user.find_or_create_scan_subscription
    @period = @subscription.periods.desc(:created_at).first
    @journals = @user.requested_account_book_types.unscoped.asc(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    @user.prescriber = @possessed_user
    @user.is_new = true
    @user.is_disabled = true
    @user.request_type = User::ADDING
    @user.set_random_password
    @user.skip_confirmation!
    @user.account_book_types = @possessed_user.my_account_book_types.default
    @user.requested_account_book_types = @possessed_user.my_account_book_types.default
    if @user.save
      subscription = @user.find_or_create_scan_subscription
      new_options = @organization.find_or_create_subscription.product_option_orders
      @organization.members << @user
      subscription.copy_to_options! new_options
      subscription.copy_to_requested_options! new_options
      subscription.save
      flash[:notice] = 'Demande de création envoyée.'
      redirect_to account_organization_customer_path(@user)
    else
      flash[:error] = 'Données invalide.'
      render action: 'new'
    end
  end

  def edit
    @user.update_request.try(:apply)
  end

  def update
    @user.assign_attributes(user_params)
    if @user.valid?
      if @user.is_new
        @user.save
      else
        @user.update_request ||= UpdateRequest.new
        update_request = @user.update_request
        update_request.temp_values = @user.changes
        @user.update_request.save
        @user.reload
        @user.set_request_type!
      end
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_customer_path(@user)
    else
      render action: :edit
    end
  end

  def stop_using
    @user.update_request.try(:apply)
    @user.is_inactive = true
    @user.request_changes
    if @user.update_request.values.empty?
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_customer_path(@user)
  end

  def restart_using
    @user.update_request.try(:apply)
    @user.is_inactive = false
    @user.request_changes
    if @user.update_request.values.empty?
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_customer_path(@user)
  end

  def search_by_code
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = User.any_of( { :organization_id => @organization.id },
                           { :group_ids.in => [@organization.id] },
                           { :collaboration_group_ids.in => [@organization.id] }).
                   where(code: /.*#{params[:q]}.*/i).asc(:code).limit(10)
      users.each do |user|
        tags << { id: user.id, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
    end
  end

private

  def user_params
    params.require(:user).permit(:code,
                                 :company,
                                 :first_name,
                                 :last_name,
                                 :email)
  end

  def load_customer
    @user = User.find params[:id]
  end

  def is_leader?
    @possessed_user == @organization.leader
  end
  helper_method :is_leader?

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
    users = @possessed_user.customers
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
      ids = is_leader? ? @organization.groups.map(&:_id) : @possessed_user['group_ids']
      ids = ids.map { |e| e.to_s }
      params[:group_ids].delete_if { |e| !e.to_s.in? ids }
      users = users.any_in(group_ids: params[:group_ids])
    end
    users
  end
end