# frozen_string_literal: true

class Account::GroupsController < Account::OrganizationController
  before_action :verify_rights, except: %w[index show]
  before_action :load_group, except: %w[index new create]

  # GET /account/organizations/:organization_id/groups
  def index
    @groups = @user.groups.search(search_terms(params[:group_contains]))
                   .order(sort_column => sort_direction)
                   .page(params[:page])
                   .per(params[:per_page])
  end

  # GET /account/organizations/:organization_id/groups/:id
  def show; end

  # GET /account/organizations/:organization_id/groups/new
  def new
    @group = @organization.groups.new
  end

  # POST /account/organizations/:organization_id/groups
  def create
    @group = @organization.groups.new safe_group_params

    if @group.save
      FileImport::Dropbox.changed(@group.collaborators)
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_groups_path(@organization)
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/groups/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/groups/:id
  def update
    previous_collaborators = @group.collaborators

    if @group.update(safe_group_params)
      collaborators = (@group.collaborators + previous_collaborators).uniq
      FileImport::Dropbox.changed(collaborators)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_groups_path(@organization)
    else
      render :edit
    end
  end

  # DELETE /account/organizations/:organization_id/groups/:id
  def destroy
    @group.destroy
    FileImport::Dropbox.changed(@group.collaborators)
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_groups_path(@organization)
  end

  private

  def verify_rights
    unless @user.leader? && @organization.is_active
      if action_name.in?(%w[new create destroy]) || (action_name.in?(%w[edit update]) && !@user.manage_groups) || !@organization.is_active
        flash[:error] = t('authorization.unessessary_rights')

        redirect_to account_organization_path(@organization)
      end
    end
  end

  def group_params
    if @user.admin?
      params.require(:group).permit(
        :name,
        :description,
        :dropbox_delivery_folder,
        :is_dropbox_authorized,
        member_ids: [],
        customer_ids: []
      )
    elsif @user.leader?
      params.require(:group).permit(
        :name,
        :description,
        member_ids: [],
        customer_ids: []
      )
    else
      params.require(:group).permit(customer_ids: [])
    end
  end

  def safe_group_params
    if @user.leader?
      safe_ids = @organization.members.map(&:id).map(&:to_s)
      ids = params[:group][:member_ids]
      ids.delete_if { |id| !id.in?(safe_ids) }
      params[:group][:member_ids] = ids
    end
    safe_ids = @organization.customers.map(&:id).map(&:to_s)
    ids = params[:group][:customer_ids]
    ids.delete_if { |id| !id.in?(safe_ids) }
    params[:group][:customer_ids] = ids

    group_params
  end

  def load_group
    @group = @organization.groups.find(params[:id])
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
