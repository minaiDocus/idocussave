# frozen_string_literal: true

class Account::GuestCollaboratorsController < Account::OrganizationController
  before_action :load_guest_collaborator, only: %w[edit update destroy]

  def index
    @account_sharings = AccountSharing.unscoped.where(account_id: customers)
    @account_sharing_groups = []
    @guest_collaborators = @organization.guest_collaborators
                                        .search(search_terms(params[:guest_collaborator_contains]))
                                        .order(sort_column => sort_direction)
                                        .page(params[:page])
                                        .per(params[:per_page])
  end

  def new
    @guest_collaborator = User.new(code: "#{@organization.code}%")
  end

  def create
    @guest_collaborator = AccountSharing::CreateContact.new(user_params, @organization).execute
    if @guest_collaborator.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_guest_collaborators_path(@organization)
    else
      render :new
    end
  end

  def edit; end

  def update
    @guest_collaborator.update(edit_user_params)
    if @guest_collaborator.save
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_guest_collaborators_path(@organization)
    else
      render :edit
    end
  end

  def destroy
    User::Collaborator::Destroy.new(@guest_collaborator).execute
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_guest_collaborators_path(@organization)
  end

  def search
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = @organization.users.active.where(
        'code REGEXP :t OR email REGEXP :t OR company REGEXP :t OR first_name REGEXP :t OR last_name REGEXP :t',
        t: params[:q].split.join('|')
      ).order(code: :asc).reject do |user|
        str = [user.code, user.email, user.company, user.first_name, user.last_name].join(' ')
        params[:q].split.detect { |e| !str.match(/#{e}/i) }
      end

      unless @user.leader?
        users = users.select do |user|
          user.is_guest || @user.customers.include?(user)
        end
      end

      users[0..9].each do |user|
        tags << { id: user.id.to_s, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json { render json: tags.to_json, status: :ok }
    end
  end

  private

  def load_guest_collaborator
    @guest_collaborator = @organization.guest_collaborators.find params[:id]
  end

  def user_params
    params.require(:user).permit(:email, :company, :first_name, :last_name)
  end

  def edit_user_params
    params.require(:user).permit(:company, :first_name, :last_name)
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
