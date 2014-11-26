# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::AccountController
  layout :layout_by_action

  before_filter :verify_suspension, only: %w(show edit update)
  before_filter :load_organization, except: %w(index new create)
  before_filter :verify_rights

  def index
    @organizations = search(organization_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
    @without_address_count = Organization.where('addresses.is_for_billing' => { '$nin' => [true] }).count
    user_ids   = DebitMandate.configured.distinct(:user_id)
    leader_ids = Organization.all.distinct(:leader_id)
    @debit_mandate_not_configured_count = Organization.where(:leader_id.in => (leader_ids - user_ids)).count
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
    @members = @organization.customers.page(params[:page]).per(params[:per])
    @periods = ::Scan::Period.where(:user_id.in => @organization.customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
    @subscription         = @organization.find_or_create_subscription
    @subscription_options = @subscription.product_option_orders.where(:group_position.gte => 1000).by_position
  end

  def edit
  end

  def update
    if @organization.update_attributes(organization_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization)
    else
      render 'edit'
    end
  end

  def suspend
    @organization.update_attribute(:is_suspended, true)
    flash[:success] = 'Suspendu avec succès.'
    redirect_to account_organizations_path
  end

  def unsuspend
    @organization.update_attribute(:is_suspended, false)
    flash[:success] = 'Activé avec succès.'
    redirect_to account_organizations_path
  end

private

  def verify_rights
    unless @user.is_admin
      authorized = false
      if current_user.is_admin && action_name.in?(%w(index new create suspend unsuspend))
        authorized = true
      elsif action_name.in?(%w(show)) && @user.is_prescriber
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
    if @user.is_admin
      @organization = Organization.find_by_slug params[:id]
      raise Mongoid::Errors::DocumentNotFound.new(Organization, params[:id]) unless @organization
    elsif @user.organization && params[:id] == @user.organization.slug
      @organization = @user.organization
    else
      redirect_to account_documents_path, flash: { error: t('authorization.unessessary_rights') }
    end
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
    organizations = Organization.all.includes(:leader)
    organizations = organizations.where(created_at:   contains[:created_at])                      unless contains[:created_at].blank?
    organizations = organizations.where(is_test:      (contains[:is_test] == '1'))                unless contains[:is_test].blank?
    organizations = organizations.where(is_suspended: (contains[:is_suspended] == '1'))           unless contains[:is_suspended].blank?
    if contains[:is_without_address].present?
      if contains[:is_without_address] == '1'
        organizations = organizations.where('addresses.is_for_billing' => { '$nin' => [true] })
      else
        organizations = organizations.where('addresses.is_for_billing' => true)
      end
    end
    if contains[:is_debit_mandate_not_configured].present?
      user_ids      = DebitMandate.configured.distinct(:user_id)
      leader_ids    = Organization.all.distinct(:leader_id)
      ids           = contains[:is_debit_mandate_not_configured] == '1' ? (leader_ids - user_ids) : user_ids
      organizations = organizations.where(:leader_id.in => ids)
    end
    organizations = organizations.where(name:         /#{Regexp.quote(contains[:name])}/i)        unless contains[:name].blank?
    organizations = organizations.where(description:  /#{Regexp.quote(contains[:description])}/i) unless contains[:description].blank?
    organizations
  end
end
