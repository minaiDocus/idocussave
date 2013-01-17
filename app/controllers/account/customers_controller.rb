# -*- encoding : UTF-8 -*-
class Account::CustomersController < Account::AccountController
  helper_method :sort_column, :sort_direction, :user_contains
  before_filter { |c| c.load_user :@possessed_user }
  before_filter :verify_management_access
  before_filter :load_customer, only: %w(show edit update stop_using restart_using)
  before_filter :verify_write_access, only: %w(edit update)

  private

  def load_customer
    @user = User.find params[:id]
  end

  public

  def index
    @users = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
    @subscription = @possessed_user.find_or_create_scan_subscription
    @period = @subscription.periods.desc(:created_at).first
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
    @user = User.new params[:user]
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
      new_options = @possessed_user.find_or_create_scan_subscription.product_option_orders
      subscription.copy_to_options! new_options
      subscription.copy_to_requested_options! new_options
      subscription.save
      flash[:notice] = "Demande de création envoyée."
      redirect_to account_user_path(@user)
    else
      flash[:error] = "Données invalide."
      render action: "new"
    end
  end

  def edit
    @user.update_request.try(:apply)
  end

  def update
    @user.assign_attributes(params[:user])
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
      redirect_to account_user_path(@user)
    else
      render action: :edit
    end
  end

  def stop_using
    @user.is_inactive = true
    @user.update_request ||= UpdateRequest.new
    update_request = @user.update_request
    update_request.temp_values = @user.changes
    @user.update_request.save
    @user.reload
    @user.set_request_type!
    flash[:notice] = "En attente de validation de l'administrateur."
    redirect_to account_user_path(@user)
  end

  def restart_using
    @user.is_inactive = false
    @user.update_request ||= UpdateRequest.new
    update_request = @user.update_request
    update_request.temp_values = @user.changes
    @user.update_request.save
    @user.reload
    @user.set_request_type!
    flash[:notice] = "En attente de validation de l'administrateur."
    redirect_to account_user_path(@user)
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end

  def sort_direction
    params[:direction] || 'desc'
  end

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

  def search(contains)
    users = @possessed_user.clients
    users = users.where(:first_name => /#{contains[:first_name]}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{contains[:last_name]}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{contains[:email]}/i) unless contains[:email].blank?
    users = users.where(:company => /#{contains[:company]}/i) unless contains[:company].blank?
    users = users.where(:code => /#{contains[:code]}/i) unless contains[:code].blank?
    users
  end
end