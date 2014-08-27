# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::AccountController
  layout :layout_by_action

  before_filter :load_organization, only: %w(show edit update)
  before_filter :verify_rights

  def index
    @organizations = search(organization_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new organization_params
    if @organization.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_path(@organization)
    else
      render 'new'
    end
  end

  def show
    if @organization
      @members = @organization.customers.page(params[:page]).per(params[:per])
      @periods = ::Scan::Period.where(:user_id.in => @organization.customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
      @subscription         = @organization.find_or_create_subscription
      @subscription_options = @subscription.product_option_orders.where(:group_position.gte => 1000).by_position
    end
  end

  def edit
  end

  def update
    if @organization
      if @organization.update_attributes(organization_params)
        flash[:success] = 'Modifié avec succès.'
        redirect_to account_organization_path(@organization)
      else
        render 'edit'
      end
    end
  end

private

  def verify_rights
    unless @user.is_admin
      authorized = false
      if action_name.in?(%w(show)) && @user.is_prescriber
        authorized = true
      elsif action_name.in?(%w(edit update)) && is_leader?
        authorized = true
      end
      unless authorized
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to account_documents_path
      end
    end
  end

  def layout_by_action
    if action_name.in?(%w(index new create))
      'inner'
    else
      'organization'
    end
  end

  def organization_params
    if @user.is_admin
      params.require(:organization).permit(
        :name,
        :code,
        :leader_id,
        :file_naming_policy,
        :is_file_naming_policy_active,
        :is_detail_authorized,
        :is_test,
        :is_journals_management_centralized
      )
    else
      params.require(:organization).permit(
        :name,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :file_naming_policy,
        :is_file_naming_policy_active,
        :is_journals_management_centralized
      )
    end
  end

  def load_organization
    @organization = Organization.find_by_slug params[:id]
  end

  def is_leader?
    @user == @organization.leader || @user.is_admin
  end
  helper_method :is_leader?

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
