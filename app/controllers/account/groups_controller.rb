# -*- encoding : UTF-8 -*-
class Account::GroupsController < Account::OrganizationController
  before_filter :verify_rights, except: %w(index show)
  before_filter :load_group, except: %w(index new create)

  def index
    @groups = search(group_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @group = @organization.groups.new
  end

  def create
    @group = @organization.groups.new safe_group_params
    if @group.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_groups_path(@organization)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @group.update(safe_group_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_groups_path(@organization)
    else
      render 'edit'
    end
  end

  def destroy
    @group.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_groups_path(@organization)
  end

private

  def verify_rights
    unless is_leader?
      if action_name.in?(%w(new create destroy)) || (action_name.in?(%w(edit update)) && @user.cannot_manage_groups?)
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to account_organization_path(@organization)
      end
    end
  end

  def group_params
    if @user.is_admin
      params.require(:group).permit(
        :name,
        :description,
        :dropbox_delivery_folder,
        :is_dropbox_authorized,
        :file_type_to_deliver,
        { member_tokens: [] }
      )
    elsif is_leader?
      params.require(:group).permit(
        :name,
        :description,
        { member_tokens: [] }
      )
    else
      params.require(:group).permit(:customer_tokens)
    end
  end

  def safe_group_params
    if is_leader?
      safe_ids = @organization.members.map(&:_id).map(&:to_s)
      ids = params[:group][:member_tokens]
      ids.delete_if { |id| !id.in?(safe_ids) }
      params[:group][:member_tokens] = ids
      group_params
    else
      safe_ids = @user.customer_ids.map(&:to_s)
      ids = params[:group][:customer_tokens]
      ids.delete_if { |id| !id.in?(safe_ids) }
      params[:group][:customer_tokens] = ids
      group_params
    end
  end

  def load_group
    @group = @organization.groups.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Group, slug: params[:id]) unless @group
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
    groups = groups.where(:name => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    groups = groups.where(:description => /#{Regexp.quote(contains[:description])}/i) unless contains[:description].blank?
    groups
  end
end
