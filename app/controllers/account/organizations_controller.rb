# -*- encoding : UTF-8 -*-
class Account::OrganizationsController < Account::AccountController
  layout :layout_by_action

  before_filter :verify_suspension, only: %w(show edit update)
  before_filter :load_organization, except: %w(index edit_options update_options new create)
  before_filter :verify_rights


  # GET /account/organizations
  def index
    @organizations = Organization.search(search_terms(params[:organization_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @without_address_count = Organization.joins(:addresses).where('addresses.is_for_billing =  ?', true ).count
    @debit_mandate_not_configured_count = DebitMandate.not_configured.count
  end


  # GET /account/organizations/:id/update_options
  def edit_options
  end


  # PUT /account/organizations/:id/update_options
  def update_options
    Settings.first.update(is_journals_modification_authorized: params[:settings][:is_journals_modification_authorized] == '1')

    flash[:success] = 'Modifié avec succès.'

    redirect_to account_organizations_path
  end


  # GET /account/organizations/new
  def new
    @organization = Organization.new
  end


  # POST /account/organizations/new
  def create
    @organization = CreateOrganization.new(organization_params).execute
    if @organization.persisted?
      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_path(@organization)
    else
      render 'new'
    end
  end


  # GET /account/organizations/:id/
  def show
    @members = @organization.customers.page(params[:page]).per(params[:per])
    @periods = Period.where(user_id: @organization.customers.pluck(:id)).where("start_date < ? AND end_date > ?", Date.today, Date.today).includes(:billings)

    @subscription         = @organization.find_or_create_subscription
    @subscription_options = @subscription.options.sort_by(&:position)
    @total                = OrganizationBillingAmountService.new(@organization).execute
  end


  # GET /account/organizations/:id/edit
  def edit
  end


  # PUT /account/organizations/:id
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


  # PUT /account/organizations/:id/suspend
  def suspend
    @organization.update_attribute(:is_suspended, true)

    flash[:success] = 'Suspendu avec succès.'

    redirect_to account_organizations_path
  end

  # PUT /account/organizations/:id/unsuspend
  def unsuspend
    @organization.update_attribute(:is_suspended, false)

    flash[:success] = 'Activé avec succès.'

    redirect_to account_organizations_path
  end


  # PUT /account/organizations/:id/activate
  def activate
    @organization.update_attribute(:is_active, true)
    flash[:success] = 'Activé avec succès.'
    redirect_to account_organization_path(@organization)
  end


  # PUT /account/organizations/:id/deactivate
  def deactivate
    DeactivateOrganization.new(@organization.id.to_s).execute

    @organization.update_attribute(:is_active, false)

    flash[:success] = 'Désactivé avec succès.'

    redirect_to account_organization_path(@organization)
  end


  # GET /account/organizations/:id/close_confirm

  def close_confirm
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
        :is_detail_authorized,
        :is_test,
        :is_quadratus_used,
        :is_coala_used,
        :is_csv_descriptor_used,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed
      )
    else
      params.require(:organization).permit(
        :name,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :is_quadratus_used,
        :is_coala_used,
        :is_csv_descriptor_used,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed
      )
    end
  end


  def load_organization
    if @user.is_admin
      @organization = Organization.find params[:id]
    elsif params[:id].to_i == @user.organization.id
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
    params[:sort] || 'name'
  end
  helper_method :sort_column


  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction


  # REFACTOR

end
