# -*- encoding : UTF-8 -*-
class Admin::UsersController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :user_contains

  before_filter :load_user, only: %w(show update send_reset_password_instructions)

  def index
    @users = search(user_contains).order_by(sort_column => sort_direction)
    respond_to do |format|
      format.html do
        @users = @users.page(params[:page]).per(params[:per_page])
      end
      format.csv do
        csv = UsersToCsvService.new(@users).execute
        send_data(csv, type: 'text/csv', filename: 'users.csv')
      end
    end
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    AccountingPlan.create(user_id: @user.id)
    if @user.save
      flash[:notice] = 'Crée avec succès.'
      redirect_to admin_users_path
    else
      flash[:error] = 'Erreur lors de la création.'
      render action: 'new'
    end
  end

  def update
    respond_to do |format|
      if params[:user][:is_prescriber]
        @user.is_prescriber = params[:user].delete(:is_prescriber)
      end
      if (params[:user].empty? && @user.save) || (params[:user].any? && @user.update_attributes(user_params))
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @user.to_json, status: :unprocessable_entity }
        format.html{ redirect_to admin_user_path(@user), error: 'Impossible de modifier cette utilisateur.' }
      end
    end
  end

  def search_by_code
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = User.where(code: /.*#{params[:q]}.*/i).asc(:code).limit(10)
      users = users.prescribers if params[:prescriber].present?
      users.each do |user|
        tags << {id: user.id, name: full_info ? user.info : user.code}
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
    end
  end

  def send_reset_password_instructions
    @user.send_reset_password_instructions
    flash[:notice] = 'Email envoyé avec succès.'
    redirect_to admin_user_path(@user)
  end

private

  def load_user
    @user = User.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:id]) unless @user
  end

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :code,
      :is_admin,
      :is_prescriber,
      :first_name,
      :last_name,
      :company,
      :knowings_code,
      :knowings_visibility,
      :is_fake_prescriber,
      :is_reminder_email_active,
      :is_document_notifier_active,
      :is_centralized,
      :is_access_by_token_active,
      :stamp_name,
      :is_stamp_background_filled
    )
  end

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
    users = User.not_operators
    users = users.where(is_admin:        (contains[:is_admin] == '1' ? true : false))      if contains[:is_admin].present?
    users = users.where(is_prescriber:   (contains[:is_prescriber] == '1' ? true : false)) if contains[:is_prescriber].present?
    users = contains[:is_inactive] == '1' ? users.closed : users.active                    if contains[:is_inactive].present?
    users = users.where(first_name:      /#{Regexp.quote(contains[:first_name])}/i)        if contains[:first_name].present?
    users = users.where(last_name:       /#{Regexp.quote(contains[:last_name])}/i)         if contains[:last_name].present?
    users = users.where(email:           /#{Regexp.quote(contains[:email])}/i)             if contains[:email].present?
    users = users.where(company:         /#{Regexp.quote(contains[:company])}/i)           if contains[:company].present?
    users = users.where(code:            /#{Regexp.quote(contains[:code])}/i)              if contains[:code].present?
    users = users.where(organization_id: contains[:organization_id])                       if contains[:organization_id].present?
    if contains[:is_organization_admin].present?
      user_ids = Organization.all.distinct(:leader_id)
      if contains[:is_organization_admin] == '1'
        users = users.where(:_id.in => user_ids)
      else
        users = users.where(:_id.nin => user_ids)
      end
    end
    users
  end
end
