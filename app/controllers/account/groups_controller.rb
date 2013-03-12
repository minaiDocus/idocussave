# -*- encoding : UTF-8 -*-
class Account::GroupsController < Account::OrganizationController
  before_filter :load_group, except: %w(index new create)

  def index
    @groups = search(group_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @group = @organization.groups.new
  end

  def create
    @group = @organization.groups.new group_params
    if @group.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_groups_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @group.ensure_authorization = true unless is_leader?
    if @group.update_attributes(group_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_groups_path
    else
      render 'edit'
    end
  end

  def destroy
    @group.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_groups_path
  end

private

  def group_params
    if is_leader?
      params.require(:group).permit(:name,
                                    :description,
                                    :member_tokens,
                                    :is_add_authorized,
                                    :is_remove_authorized,
                                    :is_create_authorized,
                                    :is_edit_authorized,
                                    :is_destroy_authorized)
    else
      params.require(:group).permit(:customer_tokens)
    end
  end

  def is_leader?
    @user == @organization.leader
  end
  helper_method :is_leader?

  def load_group
    @group = @organization.groups.find_by_slug params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def group_contains
    @contains ||= {}
    if params[:group_contains] && @contains.blank?
      @contains = params[:group_contains].delete_if do |_,value|
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
  helper_method :group_contains

  def search(contains)
    groups = is_leader? ? @organization.groups : @user.groups
    groups = groups.where(:name => /#{contains[:name]}/i) unless contains[:name].blank?
    groups = groups.where(:description => /#{contains[:description]}/i) unless contains[:description].blank?
    groups
  end
end