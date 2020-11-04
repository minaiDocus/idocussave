# frozen_string_literal: true

class Account::OrganizationsController < Account::OrganizationController
  layout :layout_by_action

  before_action :verify_suspension, only: %w[show edit update]
  before_action :load_organization, except: %w[index edit_options update_options new create]
  before_action :apply_membership
  before_action :verify_rights

  # GET /account/organizations
  def index
    @organizations = ::Organization.search(search_terms(params[:organization_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @without_address_count = Organization.joins(:addresses).where('addresses.is_for_billing =  ?', true).count
    @debit_mandate_not_configured_count = DebitMandate.not_configured.count
  end

  # GET /account/organizations/:id/update_options
  def edit_options; end

  # PUT /account/organizations/:id/update_options
  def update_options
    Settings.first.update(is_journals_modification_authorized: params[:settings][:is_journals_modification_authorized] == '1')
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organizations_path
  end

  # GET /account/organizations/:id/edit_software_users
  def edit_software_users
    @software = params[:software]
    @software_name = case @software
                     when 'coala'
                       'Coala'
                     when 'quadratus'
                       'Quadratus'
                     when 'cegid'
                       'Cegid'
                     when 'csv_descriptor'
                       'Export csv personnalisé'
                     when 'ibiza'
                       'Ibiza'
                     when 'exact_online'
                       'Exact Online'
                     when 'fec_agiris'
                       'Fec Agiris'
                     else
                       ''
                      end
  end

  # PUT /account/organizations/:id/update_software_users
  def update_software_users
    software = params[:software]
    software_users = params[:software_account_list] || ''
    @organization.customers.active.each do |customer|
      softwares_params = nil
      if software == 'coala'
        softwares_params = { is_coala_used: software_users.include?(customer.to_s) }
      elsif software == 'quadratus'
        softwares_params = { is_quadratus_used: software_users.include?(customer.to_s) }
      elsif software == 'cegid'
        softwares_params = { is_cegid_used: software_users.include?(customer.to_s) }
      elsif software == 'ibiza'
        softwares_params = { is_ibiza_used: (software_users.include?(customer.to_s) && !customer.uses_exact_online?) }
      elsif software == 'exact_online'
        softwares_params = { is_exact_online_used: (software_users.include?(customer.to_s) && !customer.uses_ibiza?) }
      elsif software == 'fec_agiris'
        softwares_params = { is_fec_agiris_used: software_users.include?(customer.to_s) }
      elsif software == 'csv_descriptor'
        softwares_params = { is_csv_descriptor_used: software_users.include?(customer.to_s) }
      end

      unless softwares_params.nil?
        customer.create_or_update_software(softwares_params)
      end
    end
    flash[:success] = 'Modifié avec succès.'
    redirect_to edit_software_users_account_organization_path(@organization, software: software)
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
    @periods = Period.where(user_id: @organization.customers.pluck(:id)).where('start_date < ? AND end_date > ?', Date.today, Date.today).includes(:billings)

    @subscription         = @organization.find_or_create_subscription
    @subscription_options = @subscription.options.sort_by(&:position)
    @total                = Billing::OrganizationBillingAmount.new(@organization).execute
  end

  # GET /account/organizations/:id/edit
  def edit; end

  # PUT /account/organizations/:id
  def update
    if @organization.update(organization_params)
      flash[:success] = 'Modifié avec succès.'
      if params[:part].present?
        redirect_to account_organization_path(@organization, tab: params[:part])
      else
        redirect_to account_organization_path(@organization)
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
  def close_confirm; end

  def prepare_payment
    debit_mandate = @organization.debit_mandate

    if debit_mandate.pending?
      debit_mandate.title             = payment_params[:gender]
      debit_mandate.firstName         = payment_params[:first_name]
      debit_mandate.lastName          = payment_params[:last_name]
      debit_mandate.email             = payment_params[:email]
      debit_mandate.invoiceLine1      = payment_params[:address]
      debit_mandate.invoiceLine2      = payment_params[:address_2]
      debit_mandate.invoiceCity       = payment_params[:city]
      debit_mandate.invoicePostalCode = payment_params[:postal_code]
      debit_mandate.invoiceCountry    = payment_params[:country]
    end

    if debit_mandate.save
      mandate = Billing::DebitMandateResponse.new debit_mandate
      mandate.prepare_order

      if mandate.errors
        render json: { success: false, message: mandate.errors }, status: 200
      else
        debit_mandate.update(reference: mandate.order_reference, transactionStatus: 'started')

        render json: { success: true, frame_64: mandate.get_frame }, status: 200
      end
    else
      render json: { success: false, message: debit_mandate.errors.message }, status: 200
    end
  end

  def confirm_payment
    debit_mandate = @organization.debit_mandate
    if debit_mandate.started?
      Billing::DebitMandateResponse.new(debit_mandate).confirm_payment
    end

    render json: { success: true, debit_mandate: @organization.debit_mandate.reload }, status: 200
  end

  def revoke_payment
    if @user.is_admin && params[:revoke_confirm] == 'true'
      result = Billing::DebitMandateResponse.new(@organization.debit_mandate).send(:revoke_payment)
      if result.present?
        flash[:error]   = result
      else
        flash[:success] = 'Mandat supprimé avec succès.'
      end
    end

    redirect_to account_organization_path(@organization, { tab: 'payments' })
  end

  private

  def verify_rights
    unless @user.is_admin
      authorized = false
      if current_user.is_admin && action_name.in?(%w[index edit_options update_options edit_software_users update_software_users new create prepare_payment confirm_payment suspend unsuspend])
        authorized = true
      elsif action_name.in?(%w[show]) && @user.is_prescriber
        authorized = true
      elsif action_name.in?(%w[edit update edit_software_users update_software_users prepare_payment confirm_payment]) && @user.leader?
        authorized = true
      end

      unless authorized
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to root_path
      end
    end
  end

  def layout_by_action
    if action_name.in?(%w[index edit_options update_options new create])
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
        :is_detail_authorized,
        :is_test,
        :is_quadratus_used,
        :is_quadratus_auto_deliver,
        :is_coala_used,
        :is_coala_auto_deliver,
        :is_cegid_used,
        :is_cegid_auto_deliver,
        :is_fec_agiris_used,
        :is_fec_agiris_auto_deliver,
        :is_csv_descriptor_used,
        :is_csv_descriptor_auto_deliver,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed,
        :is_duplicate_blocker_activated,
        :preseizure_date_option,
        :subject_to_vat,
        :invoice_mails,
        :is_exact_online_used,
        :is_exact_online_auto_deliver,
        :jefacture_api_key,
        :specific_mission
      )
    else
      params.require(:organization).permit(
        :name,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :is_quadratus_used,
        :is_quadratus_auto_deliver,
        :is_coala_used,
        :is_coala_auto_deliver,
        :is_cegid_used,
        :is_cegid_auto_deliver,
        :is_fec_agiris_used,
        :is_fec_agiris_auto_deliver,
        :is_csv_descriptor_used,
        :is_csv_descriptor_auto_deliver,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed,
        :is_duplicate_blocker_activated,
        :preseizure_date_option,
        :invoice_mails,
        :is_exact_online_used,
        :is_exact_online_auto_deliver,
        :jefacture_api_key
      )
    end
  end

  def payment_params
    params.permit(
      :gender,
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :address,
      :address_2,
      :city,
      :postal_code,
      :country
    )
  end

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction
end
