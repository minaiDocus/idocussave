class Account::CollaboratorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_member, except: %w(index new create)

  # GET /account/organizations/:organization_id/collaborators
  def index
    @members = @organization.members.
      search(search_terms(params[:user_contains])).
      order(sort_column => sort_direction).
      page(params[:page]).
      per(params[:per_page])
  end

  # GET /account/organizations/:organization_id/collaborators/:id
  def show
  end

  # GET /account/organizations/:organization_id/collaborators/new
  def new
    @member = Member.new(code: "#{@organization.code}%", role: Member::COLLABORATOR)
    @member.build_user
  end

  # POST /account/organizations/:organization_id/collaborators
  def create
    @member = CreateCollaborator.new(member_params, @organization).execute
    if @member.persisted?
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_collaborator_path(@organization, @member)
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/collaborators/:id/edit
  def edit
  end

  # PUT /account/organizations/:organization_id/collaborators/:id
  def update
    updater = UpdateCollaborator.new(@member, member_params)
    if updater.execute
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_collaborator_path(@organization, @member)
    else
      render :edit
    end
  end

  # DELETE /account/organizations/:organization_id/collaborators/:id
  def destroy
    if @member.user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
    else
      if DestroyCollaboratorService.new(@member.user).execute
        flash[:success] = 'Supprimé avec succès.'
      else
        flash[:error] = 'Impossible de supprimer.'
      end
    end

    redirect_to account_organization_collaborators_path(@organization)
  end

  private

  def verify_rights
    if @user.leader? || @member.manage_collaborators
      if action_name.in?(%w(new create destroy edit update)) && !@organization.is_active
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to account_organization_path(@organization)
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_member
    @member = @organization.members.find(params[:id])
  end

  def member_params
    attributes = [:code, { group_ids: [] }]
    attributes << :role if @user.leader?
    user_attributes = [:id, :company, :first_name, :last_name]
    user_attributes << :email if action_name.in?(%w(new create)) || (not @member.user.admin?)
    attributes << { user_attributes: user_attributes }
    # TODO2 : sanitize user id
    params.require(:member).permit(*attributes)
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
