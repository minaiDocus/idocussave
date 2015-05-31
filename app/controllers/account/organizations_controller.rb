# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::AccountController
  layout :layout_by_action

  before_filter :verify_suspension, only: %w(show edit update)
  before_filter :load_organization, except: %w(index edit_options update_options new create)
  before_filter :verify_rights

  def index
    @organizations = search(organization_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @without_address_count = Organization.where('addresses.is_for_billing' => { '$nin' => [true] }).count
    user_ids   = DebitMandate.configured.distinct(:user_id)
    leader_ids = Organization.all.distinct(:leader_id)
    @debit_mandate_not_configured_count = Organization.where(:leader_id.in => (leader_ids - user_ids)).count
  end

  def edit_options
  end

  def update_options
    organization_ids = params[:subscription_options][:organization_ids].compact
    Organization.where(:_id.in => organization_ids).update_all(is_subscription_lower_options_enabled: true)
    Organization.where(:_id.nin => organization_ids).update_all(is_subscription_lower_options_enabled: false)
    Settings.is_journals_modification_authorized = params[:settings][:is_journals_modification_authorized] == '1'
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organizations_path
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
    @periods = Period.where(:user_id.in => @organization.customers.map(&:_id), :start_at.lt => Time.now, :end_at.gt => Time.now).entries
    @subscription         = @organization.find_or_create_subscription
    @subscription_options = @subscription.options.sort_by(&:group_position)
    @total                = OrganizationBillingAmountService.new(@organization).execute
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      flash[:success] = 'Modifié avec succès.'
      if params[:part] != 'other_software'
        redirect_to account_organization_path(@organization)
      else
        redirect_to account_organization_path(@organization, tab: 'other_software')
      end
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
      if current_user.is_admin && action_name.in?(%w(index edit_options update_options new create suspend unsuspend))
        authorized = true
      elsif action_name.in?(%w(show)) && @user.is_prescriber
        authorized = true
      elsif action_name.in?(%w(edit update)) && is_leader?
        authorized = true
      end
      unless authorized
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to root_path
      end
    end
  end

  def layout_by_action
    if action_name.in?(%w(index edit_options update_options new create))
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
        :is_journals_management_centralized,
        :is_quadratus_used,
        :is_pre_assignment_date_computed
      )
    else
      params.require(:organization).permit(
        :name,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :file_naming_policy,
        :is_file_naming_policy_active,
        :is_journals_management_centralized,
        :is_quadratus_used,
        :is_pre_assignment_date_computed
      )
    end
  end

  def load_organization
    if @user.is_admin
      @organization = Organization.find_by_slug! params[:id]
      raise Mongoid::Errors::DocumentNotFound.new(Organization, slug: params[:id]) unless @organization
    elsif @user.organization && params[:id] == @user.organization.slug
      @organization = @user.organization
    else
      redirect_to root_path, flash: { error: t('authorization.unessessary_rights') }
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
