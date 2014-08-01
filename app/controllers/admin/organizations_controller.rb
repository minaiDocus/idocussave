# -*- encoding : UTF-8 -*-
class Admin::OrganizationsController < Admin::AdminController
  layout :layout_by_action

  before_filter :load_organization, except: %w(index new create)

  def index
    @organizations = search(organization_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new organization_params
    if @organization.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_organization_path(@organization)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @organization.update_attributes(organization_params)
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_organization_path(@organization)
    else
      render 'edit'
    end
  end

  def destroy
    @organization.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_organizations_path
  end

private

  def layout_by_action
    if action_name == 'select_propagation_options'
      nil
    else
      'admin'
    end
  end

  def organization_params
    params.require(:organization).permit!
  end

  def load_organization
    @organization = Organization.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:id]) unless @organization
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def organization_contains
    @contains ||= {}
    if params[:organization_contains] && @contains.blank?
      @contains = params[:organization_contains].delete_if do |key,value|
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
  helper_method :organization_contains

  def search(contains)
    organizations = Organization.all
    organizations = organizations.where(name:        /#{Regexp.quote(contains[:name])}/i)        unless contains[:name].blank?
    organizations = organizations.where(description: /#{Regexp.quote(contains[:description])}/i) unless contains[:description].blank?
    organizations
  end
end
