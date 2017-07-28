class Account::GuestCollaboratorsController < Account::OrganizationController
  before_action :load_guest_collaborator, only: %w(edit update destroy)

  def index
    @account_sharings = @organization.account_sharings
    @account_sharing_groups = []
    @guest_collaborators = @organization.guest_collaborators.
      search(search_terms(params[:guest_collaborator_contains])).
      order(sort_column => sort_direction).
      page(params[:page]).
      per(params[:per_page])
  end

  def new
    @guest_collaborator = User.new(code: "#{@organization.code}%")
  end

  def create
    @guest_collaborator = CreateGuestCollaborator.new(user_params, @organization).execute
    if @guest_collaborator.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_guest_collaborators_path(@organization)
    else
      render :new
    end
  end

  def edit
  end

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
    @guest_collaborator.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_guest_collaborators_path(@organization)
  end

private

  def load_guest_collaborator
    @guest_collaborator = @organization.guest_collaborators.find params[:id]
  end

  def user_params
    params.require(:user).permit(:code, :email, :company, :first_name, :last_name)
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
