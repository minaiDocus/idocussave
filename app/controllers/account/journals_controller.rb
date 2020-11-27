# frozen_string_literal: true

class Account::JournalsController < Account::OrganizationController
  before_action :load_customer, except: %w[index]
  before_action :verify_rights
  before_action :verify_if_customer_is_active
  before_action :redirect_to_current_step
  before_action :load_journal, only: %w[edit update destroy edit_analytics update_analytics delete_analytics sync_analytics]
  before_action :verify_max_number, only: %w[new create select copy]

  # GET /account/organizations/:organization_id/journals
  def index
    @journals = @organization.account_book_types.order(is_default: :desc, name: :asc)
  end

  # GET /account/organizations/:organization_id/journals/new
  def new
    @journal = AccountBookType.new
  end

  # POST /account/organizations/:organization_id/journals
  def create
    @journal = Journal::Handling.new({ owner: (@customer || @organization), params: journal_params, current_user: current_user, request: request }).insert
    if !@journal.errors.messages.present?
      text = "Nouveau journal #{ @journal.name } créé avec succès"

      if params[:new_create_book_type].present?
        render json: { success: true, response: { text: text } }, status: 200
      else
        flash[:success] = text
        if @customer
          redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
        else
          redirect_to account_organization_journals_path(@organization)
        end
      end
    else
      if params[:new_create_book_type].present?
        render json: { success: true, response: @journal.errors.messages }, status: 200
      else
        render :new
      end
    end
  end

  # GET /account/organizations/:organization_id/journals/edit_analytics
  def edit_analytics
    unless @customer
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_journals_path(@organization)
    end
  end

  # PUT /account/organizations/:organization_id/journals/:journal_id/edit_analytics
  def update_analytics
    if @customer
      analytic_reference = Journal::AnalyticReferences.new(@journal)
      if analytic_reference.add(params[:analytic])
        flash[:success] = 'Modifié avec succès.'
      else
        flash[:error] = analytic_reference.error_messages
      end
      redirect_to edit_analytics_account_organization_customer_journals_path(@organization, @customer, id: @journal)
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_journals_path(@organization)
    end
  end

  def sync_analytics
    if @customer
      analytic_reference = Journal::AnalyticReferences.new(@journal)
      if analytic_reference.synchronize
        flash[:success] = 'Synchronisé avec succès.'
      else
        flash[:error]   = "Erreur de synchronisation - #{analytic_reference.error_messages}"
      end
      redirect_to edit_analytics_account_organization_customer_journals_path(@organization, @customer, id: @journal)
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_journals_path(@organization)
    end
  end

  # GET /account/organizations/:organization_id/journals/edit
  def edit; end

  # PUT /account/organizations/:organization_id/journals/:journal_id
  def update
    journal = Journal::Handling.new({journal: @journal, params: journal_params, current_user: current_user, request: request}).update

    if !journal.errors.messages.present?
      text = "Le journal #{journal.name} a été modifié avec succès."

      if params[:new_create_book_type].present?
        render json: { success: true, response: { text: text } }, status: 200
      else
        flash[:success] = text
        if @customer
          redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
        else
          redirect_to account_organization_journals_path(@organization)
        end
      end
    else
      if params[:new_create_book_type].present?
        render json: { success: true, response: journal.errors.messages }, status: 200
      else
        render :edit
      end
    end
  end

  # DELETE /account/organizations/:organization_id/journals/:journal_id
  def destroy
    if @user.is_admin || Settings.first.is_journals_modification_authorized || !@customer || @journal.is_open_for_modification?
      Journal::Handling.new({journal: @journal, current_user: current_user, request: request}).destroy

      flash[:success] = 'Supprimé avec succès.'
      if @customer
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
      else
        redirect_to account_organization_journals_path(@organization)
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  # GET /account/organizations/:organization_id/journals/:journal_id/select
  def select
    @journals = @organization.account_book_types.order(is_default: :desc).order(name: :asc)
  end

  # GET /account/organizations/:organization_id/journals/:journal_id/copy
  def copy
    valid_ids = @organization.account_book_types.map(&:id).map(&:to_s)

    ids = (params[:journal_ids].presence || []).select do |journal_id|
      journal_id.in? valid_ids
    end

    copied_ids = []

    ids.each do |id|
      next if is_max_number_reached?

      journal = AccountBookType.find id

      #next unless !journal.compta_processable? || is_preassignment_authorized?

      copy              = journal.dup
      copy.user         = @customer
      copy.organization = nil
      copy.is_default   = nil

      next unless copy.save

      copied_ids << id

      Journal::UpdateRelation.new(copy).execute

      CreateEvent.add_journal(copy, @customer, current_user, path: request.path, ip_address: request.remote_ip)
    end

    if ids.count == 0
      flash[:error] = 'Aucun journal sélectionné.'
    elsif copied_ids.count == 0
      flash[:error] = 'Aucun journal copié.'
    elsif ids.count == copied_ids.count
      flash[:success] = "#{copied_ids.count} journal(s) copié(s)."
    else
      flash[:notice] = "#{copied_ids.count}/#{ids.count} journal(s) copié(s)."
    end

    FileImport::Dropbox.changed(@customer) if copied_ids.count > 0

    redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
  end

  private

  def verify_rights
    is_ok = false
    if @organization.is_active
      is_ok = true if @user.leader?
      is_ok = true if !is_ok && !@customer && @user.manage_journals
      is_ok = true if !is_ok && @customer && @user.manage_customer_journals
    end
    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer&.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def journal_params
    attrs = %i[
      pseudonym
      use_pseudonym_for_import
      description
      instructions
      position
      is_default
    ]

    if @user.is_admin || Settings.first.is_journals_modification_authorized || !@customer || !@journal || @journal.is_open_for_modification?
      attrs << :name
    end

    if is_preassignment_authorized? || @customer.subscription.is_package?('ido_x')
      attrs += %i[
        domain
        entry_type
        currency
        account_type
        meta_account_number
        meta_charge_account
        vat_accounts
        anomaly_account
        jefacture_enabled
      ]
    end

    attrs << :is_expense_categories_editable if current_user.is_admin
    attributes = params.require(:account_book_type).permit(*attrs)

    if @journal&.is_expense_categories_editable || current_user.is_admin
      if params[:account_book_type][:expense_categories_attributes].present?
        attributes[:expense_categories_attributes] = params[:account_book_type][:expense_categories_attributes].permit!
      end
    end

    attributes[:jefacture_enabled] = attributes[:jefacture_enabled].to_s.gsub('1', 'true').gsub('0', 'false') if is_preassignment_authorized?
    attributes
  end

  def load_customer
    if params[:customer_id].present?
      @customer = customers.find params[:customer_id]
    end
  end

  def load_journal
    @journal = (@customer || @organization).account_book_types.find params[:id]
  end

  def is_max_number_reached?
    @customer.account_book_types.count >= @customer.options.max_number_of_journals
  end
  helper_method :is_max_number_reached?

  def is_preassignment_authorized?
    @customer.nil? || @customer.options.is_preassignment_authorized || @organization.specific_mission || @customer.subscription.is_package?('ido_x')
  end
  helper_method :is_preassignment_authorized?

  def verify_max_number
    if @customer && is_max_number_reached?
      text = "Nombre maximum de journaux comptables atteint : #{@customer.account_book_types.count}/#{@customer.options.max_number_of_journals}."
      if params[:new_create_book_type].present?
        render json: { success: true, response: text }, status: 200
      else
        flash[:error] = text
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
      end
    end
  end
end
