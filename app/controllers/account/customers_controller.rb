# frozen_string_literal: true

class Account::CustomersController < Account::OrganizationController
  before_action :load_customer, except: %w[index info form_with_first_step new create search]
  before_action :verify_rights, except: 'index'
  before_action :verify_if_customer_is_active, only: %w[edit update edit_period_options update_period_options edit_knowings_options update_knowings_options edit_compta_options update_compta_options]
  before_action :redirect_to_current_step
  before_action :verify_if_account_can_be_closed, only: %w[account_close_confirm close_account]

  # GET /account/organizations/:organization_id/customers
  def index
    respond_to do |format|
      format.html do
        if params[:group_ids].present?
          params[:user_contains][:group_ids] = params[:group_ids]
        end
        @customers = customers.search(search_terms(params[:user_contains]))
                              .order(sort_column => sort_direction)
                              .page(params[:page])
                              .per(params[:per_page])
        @periods = Period.where(user_id: @customers.pluck(:id)).where('start_date < ? AND end_date > ?', Date.today, Date.today).includes(:user, :product_option_orders)
        @groups = @user.groups.order(name: :asc)
      end

      format.json do
        @customers = search(user_contains).order(sort_column => sort_direction).active
      end
    end
  end

  # GET /account/organizations/:organization_id/customers/:id
  def show
    @subscription     = @customer.subscription
    @period           = @subscription.periods.order(created_at: :desc).first
    @journals         = @customer.account_book_types.order(name: :asc)
    @pending_journals = @customer.retrievers.where(journal_id: nil).where.not(journal_name: [nil]).distinct.pluck(:journal_name)
    @customer.build_softwares if @customer.softwares.nil?
  end

  # GET /account/organizations/:organization_id/customers/info
  def info; end

  # GET /account/organizations/:organization_id/customers/:id/new_customer_step_two
  def new_customer_step_two;  end

  # GET /account/organizations/:organization_id/customers/:id/book_type_creator/:journal_id
  def book_type_creator
    @journal = AccountBookType.where(id: params[:journal_id]).first.presence || AccountBookType.new

    render partial: 'book_type_creator'
  end

  def refresh_book_type
    render partial: 'book_type'
  end

  # GET /account/organizations/:organization_id/customers/form_with_first_step
  def form_with_first_step
    @customer = User.new(code: "#{@organization.code}%")
  end

  # GET /account/organizations/:organization_id/customers/new
  def new; end

  # POST /account/organizations/:organization_id/customers
  def create
    @customer = Subscription::CreateCustomer.new(@organization, @user, user_params, current_user, request).execute

    unless @organization.specific_mission
      modif_params = params[:subscription][:subscription_option]
      params[:subscription][modif_params] = true
    end

    if @customer.persisted?
      if @organization.specific_mission
        redirect_to account_organization_customer_path(@organization, @customer)
      else
        Subscription::Form.new(@customer.subscription, @user, request).submit(params[:subscription])

        redirect_to new_customer_step_two_account_organization_customer_path(@organization, @customer)
      end
    else
      _error_messages = @customer.errors.messages
      html_ul_content = "<ul>"
      _error_messages.each {|key, value| html_ul_content += "<li>#{key} : #{value.join(', ')}</li>"}
      html_ul_content += "</ul>"

      flash[:error] = html_ul_content.html_safe
      render :form_with_first_step
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/customers/:id
  def update
    if params[:user][:softwares_attributes].present?
      software = @customer.create_or_update_software(params[:user][:softwares_attributes])
      if software&.persisted?
        flash[:success] = 'Modifié avec succès.'
      else
        flash[:error] = 'Impossible de modifier.'
      end

      redirect_to account_organization_customer_path(@organization, @customer, tab: params[:part])
    else
      @customer.is_group_required = @user.not_leader?

      if Subscription::UpdateCustomer.new(@customer, user_params).execute
        flash[:success] = 'Modifié avec succès'

        redirect_to account_organization_customer_path(@organization, @customer)
      else
        render :edit
      end
    end
  end

  def edit_software
    @customer.build_softwares if @customer.softwares.nil?
    @software = params[:software]
  end

  def update_software
    software = @customer.create_or_update_software(params[:user][:softwares_attributes])
    if software&.persisted?
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de modifier.'
    end
    redirect_to account_organization_customer_path(@organization, @customer, tab: params[:software])
  end

  def edit_softwares_selection
    if @customer.configured?
      redirect_to account_organization_customer_path(@organization, @customer)
    else
      @customer.build_softwares if @customer.softwares.nil?
    end
  end

  def update_softwares_selection
    software = @customer.create_or_update_software(params[:user][:softwares_attributes])
    next_configuration_step
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_exact_online
  def edit_exact_online
    @customer.build_exact_online if @customer.exact_online.nil?
  end

  # PUT /account/organizations/:organization_id/customers/:id/update_exact_online
  def update_exact_online
    api_keys = @customer.exact_online.try(:api_keys)

    @customer.assign_attributes(exact_online_params)

    is_api_keys_changed = @customer.exact_online.try(:client_id) != api_keys.try(:[], :client_id) || @customer.exact_online.try(:client_secret) != api_keys.try(:[], :client_secret)

    if @customer.save
      if @customer.configured?
        flash[:success] = 'Modifié avec succès'

        if is_api_keys_changed && exact_online_params[:exact_online_attributes][:client_id].present? && exact_online_params[:exact_online_attributes][:client_secret].present?
          @customer.exact_online.try(:reset)
          redirect_to authenticate_account_exact_online_path(customer_id: @customer.id)
        else
          redirect_to account_organization_customer_path(@organization, @customer, tab: 'exact_online')
        end
      else
        next_configuration_step
      end
    else
      flash[:error] = 'Impossible de modifier'
      render 'edit'
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_ibiza
  def edit_ibiza; end

  # PUT /account/organizations/:organization_id/customers/:id/update_ibiza
  def update_ibiza
    @customer.assign_attributes(ibiza_params)

    is_ibiza_id_changed = @customer.ibiza_id_changed?

    if @customer.save
      if @customer.configured?
        if is_ibiza_id_changed && @user.ibiza_id.present?
          AccountingPlan::IbizaUpdate.new(@user).run
        end

        flash[:success] = 'Modifié avec succès'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'ibiza')
      else
        next_configuration_step
      end
    else
      flash[:error] = 'Impossible de modifier'
      render 'edit'
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_period_options
  def edit_period_options; end

  # PUT /account/organizations/:organization_id/customers/:id/update_period_options
  def update_period_options
    if @customer.update(period_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'period_options')
      else
        next_configuration_step
      end
    else
      render 'edit_period_options'
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_knowings_options
  def edit_knowings_options; end

  # PUT /account/organizations/:organization_id/customers/:id/update_knowings_options
  def update_knowings_options
    if @customer.update(knowings_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'ged')
      else
        next_configuration_step
      end
    else
      render 'edit_knowings_options'
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/edit_compta_options
  def edit_compta_options; end

  # PUT /account/organizations/:organization_id/customers/:id/update_compta_options
  def update_compta_options
    if @customer.update(compta_options_params)
      if @customer.configured?
        flash[:success] = 'Modifié avec succès.'

        redirect_to account_organization_customer_path(@organization, @customer, tab: 'compta')
      else
        next_configuration_step
      end
    else
      render 'edit_compta_options'
    end
  end

  def edit_mcf; end

  def upload_email_infos
    if @customer.options.try(:is_upload_authorized) && @customer.active?
      render :upload_by_email
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end

  def show_mcf_errors
    order_by = params[:sort] || 'created_at'
    direction = params[:direction] || 'desc'

    @mcf_documents_error = @customer.mcf_documents.not_processable.order(order_by => direction).page(params[:page]).per(20)
    render :show_mcf_errors
  end

  def retake_mcf_errors
    if params[:confirm_unprocessable_mcf].present?
      confirm_unprocessable_mcf
    elsif params[:retake_mcf_documents].present?
      retake_mcf_documents
    end

    redirect_to show_mcf_errors_account_organization_customer_path(@organization, @customer)
  end

  def update_mcf
    if @customer.update(mcf_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'mcf')
    else
      render :edit_mcf
    end
  end

  # GET /account/organizations/:organization_id/customers/:id/account_close_confirm
  def account_close_confirm; end

  # PUT /account/organizations/:organization_id/customers/:id/close_account
  def close_account
    if Subscription::Stop.new(@customer, params[:close_now]).execute
      flash[:success] = 'Dossier clôturé avec succès.'
    else
      flash[:error] = 'Impossible de clôturer immédiatement le dossier, la période a été en partie facturé.'
    end
    redirect_to account_organization_customer_path(@organization, @customer)
  end

  # /account/organizations/:organization_id/customers/:id/account_reopen_confirm
  def account_reopen_confirm; end

  # PUT /account/organizations/:organization_id/customers/:id/reopen_account(.:format)
  def reopen_account
    Subscription::Reopen.new(@customer, @user, request).execute
    flash[:success] = 'Dossier réouvert avec succès.'
    redirect_to account_organization_customer_path(@organization, @customer)
  end

  def search
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = @user.leader? ? @organization.customers.active : @user.customers.active
      users = users.where('code REGEXP :t OR company REGEXP :t OR first_name REGEXP :t OR last_name REGEXP :t', t: params[:q].split.join('|')).order(code: :asc).limit(10).select do |user|
        str = [user.code, user.company, user.first_name, user.last_name].join(' ')
        params[:q].split.detect { |e| !str.match(/#{e}/i) }.nil?
      end
      users.each do |user|
        tags << { id: user.id.to_s, name: full_info ? user.info : user.code }
      end
    end

    respond_to do |format|
      format.json { render json: tags.to_json, status: :ok }
    end
  end

  private

  def can_manage?
    @user.leader? || @user.manage_customers
  end

  def verify_rights
    authorized = true
    authorized = false unless can_manage?
    if action_name.in?(%w[account_close_confirm close_account]) && params[:close_now] == '1' && !@user.is_admin
      authorized = false
    end
    if action_name.in?(%w[info new create destroy]) && !@organization.is_active
      authorized = false
    end
    if action_name.in?(%w[info new create]) && !(@user.leader? || @user.groups.any?)
      authorized = false
    end
    if action_name.in?(%w[edit_period_options update_period_options]) && !@customer.options.is_upload_authorized
      authorized = false
    end
    if action_name.in?(%w[edit_ibiza update_ibiza]) && !@organization.ibiza.try(:configured?)
      authorized = false
    end
    if action_name.in?(%w[edit_exact_online update_exact_online]) && !@organization.is_exact_online_used
      authorized = false
    end

    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_account_can_be_closed
    if !@customer.subscription.commitment_end?(false) && !params[:close_now]
      flash[:error] = 'Ce dossier est souscrit à un forfait avec un engagement de 12 mois'

      redirect_to account_organization_customer_path(@organization, @customer)
    end
  end

  def user_params
    attributes = [
      :company,
      :first_name,
      :last_name,
      :email,
      :is_pre_assignement_displayed,
      :phone_number,
      :manager_id,
      :jefacture_account_id,
      { group_ids: [] },
      { options_attributes: %i[id is_taxable is_pre_assignment_date_computed] },
      { softwares_attributes: %i[id is_ibiza_used is_coala_used is_quadratus_used is_csv_descriptor_used is_exact_online_used is_cegid_used is_fec_agiris_used] }
    ]

    if @user.is_admin
      attributes[-1][:softwares_attributes] << :use_own_csv_descriptor_format
    end

    if params[:user].try(:[], :softwares_attributes).try(:[], :is_ibiza_used)
      attributes << :ibiza_id
    end

    attributes << :code if action_name == 'create'

    params.require(:user).permit(*attributes)
  end

  def ibiza_params
    params.require(:user).permit(:ibiza_id, softwares_attributes: %i[id is_ibiza_auto_deliver is_ibiza_compta_analysis_activated is_ibiza_analysis_to_validate])
  end

  def exact_online_params
    params.require(:user).permit(exact_online_attributes: %i[id client_id client_secret], softwares_attributes: %i[id is_exact_online_auto_deliver])
  end

  def period_options_params
    if current_user.is_admin
      params.require(:user).permit(
        :authd_prev_period,
        :auth_prev_period_until_day,
        :auth_prev_period_until_month
      )
    else
      params.require(:user).permit(
        :authd_prev_period,
        :auth_prev_period_until_day
      )
    end
  end

  def knowings_options_params
    params.require(:user).permit(:knowings_code, :knowings_visibility)
  end

  def compta_options_params
    params.require(:user).permit(options_attributes: %i[
                                   id
                                   is_taxable
                                   is_pre_assignment_date_computed
                                   is_operation_processing_forced
                                   is_operation_value_date_needed
                                   preseizure_date_option
                                 ])
  end

  def mcf_params
    params.require(:user).permit(:mcf_storage)
  end

  def retake_mcf_documents
    mcf_documents_errors = @customer.mcf_documents.where(id: params[:mcf_documents_ids])
    if mcf_documents_errors.any?
      mcf_documents_errors.each(&:reset)
      flash[:success] = 'Récupération en cours...'
    end
  end


  def confirm_unprocessable_mcf
    unprocessable_mcf = @customer.mcf_documents.where(id: params[:mcf_documents_ids]).not_processable
    if unprocessable_mcf.any?
      unprocessable_mcf.each(&:confirm_unprocessable)
      flash[:success] = 'Modifié avec succès.'
    else
      flash[:error] = 'Impossible de traiter la demande.'
    end
  end

  def load_customer
    @customer = customers.find(params[:id])
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def is_max_number_of_journals_reached?
    @customer.account_book_types.count >= @customer.options.max_number_of_journals
  end
  helper_method :is_max_number_of_journals_reached?
end
