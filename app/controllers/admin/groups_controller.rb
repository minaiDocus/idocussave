# -*- encoding : UTF-8 -*-
class Admin::GroupsController < Admin::AdminController
  before_filter :load_organization
  before_filter :load_group, except: %w(new create)
  before_filter :load_breadcrumbs

  def show
  end

  def new
    @group = Group.new
  end

  def create
    @group = @organization.groups.new group_params
    if @group.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_organization_group_path(@organization, @group)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @group.update_attributes(group_params)
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_organization_group_path(@organization, @group)
    else
      render 'edit'
    end
  end

  def destroy
    @group.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_organization_path(@organization)
  end

private

  def group_params
    params.require(:group).permit!
  end

  def load_organization
    @organization = Organization.find_by_slug params[:organization_id]
    raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:organization_id]) unless @organization
  end

  def load_group
    @group = Group.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Group, params[:id]) unless @group
  end

  def load_breadcrumbs
    add_breadcrumb 'Organisations', :admin_organizations_path
    add_breadcrumb @organization.name, admin_organization_path(@organization)
    if action_name.in? %w(new create)
      add_breadcrumb "(#{I18n.t('actions.new')})", new_admin_organization_group_path(@organization)
    else
      add_breadcrumb @group.name, admin_organization_group_path(@organization, @group)
    end
  end

end