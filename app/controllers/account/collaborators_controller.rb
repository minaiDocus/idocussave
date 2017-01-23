# -*- encoding : UTF-8 -*-
class Account::CollaboratorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_collaborator, except: %w(index new create)


  # /account/organizations/:organization_id/collaborators
  def index
    @collaborators = User.search_for_collection(@organization.collaborators, search_terms(params[:user_contains])).order(sort_column => sort_direction)

    @collaborators_count = @collaborators.count

    @collaborators = @collaborators.page(params[:page]).per(params[:per_page])
  end


  # GET /account/organizations/:organization_id/collaborators/:id
  def show
  end


  # /account/organizations/:organization_id/collaborators/new
  def new
    @collaborator = User.new(code: "#{@organization.code}%")
  end

  # POST /account/organizations/:organization_id/collaborators
  def create
    if @collaborator = CreateCollaborator.new(user_params, @organization).execute

      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_collaborator_path(@organization, @collaborator)
    else
      render :new
    end
  end


  # GET /account/organizations/:organization_id/collaborators/:id/edit
  def edit
  end


  # PUT /account/organizations/:organization_id/collaborators/:id
  def update
    if @collaborator = UpdateCollaborator.new(@collaborator, user_params).execute

      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_collaborator_path(@organization, @collaborator)
    else
      render :edit
    end
  end


  # DELETE /account/organizations/:organization_id/collaborators/:id
  def destroy
    if @collaborator.is_admin
      flash[:error] = t('authorization.unessessary_rights')
    else
      if DestroyCollaboratorService.new(@collaborator).execute
        flash[:success] = 'Supprimé avec succès.'
      else
        flash[:error] = 'Impossible de supprimer.'
      end
    end

    redirect_to account_organization_collaborators_path(@organization)
  end


  private


  def verify_rights
    if is_leader? || @user.can_manage_collaborators?
      if action_name.in?(%w(new create destroy edit update)) && !@organization.is_active
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to account_organization_path(@organization)
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_collaborator
    @collaborator = @organization.collaborators.find(params[:id])
  end


  def user_params
    attributes = [
      :code,
      { group_ids: [] },
      :company,
      :first_name,
      :last_name
    ]
    if action_name.in?(%w(new create)) || !@collaborator.is_admin
      attributes << :email
    end
    params.require(:user).permit(*attributes)
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
