# frozen_string_literal: true

class Admin::UsersController < Admin::AdminController
  helper_method :sort_column, :sort_direction

  before_action :load_user, only: %w[show update send_reset_password_instructions]

  # GET /admin/users
  def index
    @user_contains = search_terms(params[:user_contains])

    @users = User.not_operators.search(@user_contains).order(sort_column => sort_direction)

    @users_count = @users.count

    respond_to do |format|
      format.html do
        @users = @users.page(params[:page]).per(params[:per_page])
      end
      format.csv do
        csv = User::ToCsv.new(@users).execute
        send_data(csv, type: 'text/csv', filename: 'users.csv')
      end
    end
  end

  # GET /admin/users/:id
  def show; end

  # PUT /admin/users/:id
  def update
    respond_to do |format|
      if params[:user][:is_prescriber]
        @user.is_prescriber = params[:user].delete(:is_prescriber)
      end

      if (params[:user].empty? && @user.save) || (params[:user].any? && @user.update(user_params))
        format.json { render json: {}, status: :ok }
        format.html { redirect_to admin_user_path(@user) }
      else
        format.json { render json: @user.to_json, status: :unprocessable_entity }
        format.html { redirect_to admin_user_path(@user), error: 'Impossible de modifier cette utilisateur.' }
      end
    end
  end

  # GET /admin/users/search_by_code
  def search_by_code
    tags = []

    full_info = params[:full_info].present?

    if params[:q].present?
      users = User.where('code LIKE ?', "%#{params[:q]}%").order(code: :asc).limit(10)

      users = users.prescribers if params[:prescriber].present?

      users.each do |user|
        tags << { id: user.id.to_s, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json { render json: tags.to_json, status: :ok }
    end
  end

  # GET /admin/users/:id/send_reset_password_instructions
  def send_reset_password_instructions
    @user.send_reset_password_instructions

    flash[:notice] = 'Email envoyé avec succès.'

    redirect_to admin_user_path(@user)
  end

  private

  def load_user
    @user = User.find params[:id]
  end

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :code,
      :first_name,
      :last_name,
      :company,
      :knowings_code,
      :knowings_visibility,
      :is_fake_prescriber,
      :is_access_by_token_active,
      :stamp_name,
      :is_stamp_background_filled
    )
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
