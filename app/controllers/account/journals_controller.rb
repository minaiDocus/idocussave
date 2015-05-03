# -*- encoding : UTF-8 -*-
class Account::JournalsController < Account::OrganizationController
  before_filter :load_customer, except: %w(index)
  before_filter :verify_rights
  before_filter :verify_if_customer_is_active
  before_filter :load_journal, only: %w(edit update destroy)
  before_filter :verify_max_number, only: %w(new create select copy)

  def index
    @journals = source.account_book_types.desc(:is_default).asc(:name)
  end

  def new
    @journal = AccountBookType.new
  end

  def create
    @journal = AccountBookType.new journal_params
    (@customer || source).account_book_types << @journal
    if @journal.save
      flash[:success] = 'Créé avec succès.'
      if @customer
        UpdateJournalRelationService.new(@journal).execute
        EventCreateService.new.add_journal(@journal, @customer, current_user, path: request.path, ip_address: request.remote_ip)
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
      else
        redirect_to account_organization_journals_path(@organization)
      end
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @journal.assign_attributes(journal_params)
    changes = @journal.changes.dup
    if @journal.save
      flash[:success] = 'Modifié avec succès.'
      if @customer
        UpdateJournalRelationService.new(@journal).execute
        EventCreateService.new.journal_update(@journal, @customer, changes, current_user, path: request.path, ip_address: request.remote_ip)
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
      else
        redirect_to account_organization_journals_path(@organization)
      end
    else
      render action: 'edit'
    end
  end

  def destroy
    if @user.is_admin || Settings.is_journals_modification_authorized || !@customer || @journal.is_open_for_modification?
      @journal.destroy
      flash[:success] = 'Supprimé avec succès.'
      if @customer
        UpdateJournalRelationService.new(@journal).execute
        EventCreateService.new.remove_journal(@journal, @customer, current_user, path: request.path, ip_address: request.remote_ip)
        redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
      else
        redirect_to account_organization_journals_path(@organization)
      end
    else
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def select
    @journals = source.account_book_types.desc(:is_default).asc(:name)
    @journals = @journals.not_compta_processable unless @customer.options.is_preassignment_authorized
  end

  def copy
    valid_ids = @organization.account_book_types.map(&:id).map(&:to_s)
    ids = (params[:journal_ids].presence || []).select do |journal_id|
      journal_id.in? valid_ids
    end
    copied_ids = []
    ids.each do |id|
      unless is_max_number_reached?
        journal = AccountBookType.find id
        if !journal.compta_processable? || is_preassignment_authorized?
          copy = journal.dup
          copy.user         = @customer
          copy.organization = nil
          copy.is_default   = nil
          copy._slugs       = []
          if copy.save
            copied_ids << id
            UpdateJournalRelationService.new(copy).execute
            EventCreateService.new.add_journal(copy, @customer, current_user, path: request.path, ip_address: request.remote_ip)
          end
        end
      end
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
    redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
  end

private

  def verify_rights
    is_ok = false
    is_ok = true if is_leader?
    is_ok = true if !is_ok && !@customer && @user.can_manage_journals?
    is_ok = true if !is_ok && @customer && @user.rights.is_customer_journals_management_authorized
    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer && @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def journal_params
    attrs = [
      :pseudonym,
      :description,
      :instructions,
      :position,
      :is_default
    ]
    attrs << :name if @user.is_admin || Settings.is_journals_modification_authorized || !@customer || !@journal || @journal.is_open_for_modification?
    attributes = params.require(:account_book_type).permit(*attrs)
    if is_preassignment_authorized?
      attributes.merge!(params.require(:account_book_type).permit(
        :domain,
        :entry_type,
        :default_account_number,
        :account_number,
        :default_charge_account,
        :charge_account,
        :vat_account,
        :anomaly_account
      ))
    end
    if current_user.is_admin
      attributes.merge!(params.require(:account_book_type).permit(:is_expense_categories_editable))
    end
    if (@journal && @journal.is_expense_categories_editable) || current_user.is_admin
      if params[:account_book_type][:expense_categories_attributes].present?
        attributes.merge!({
          expense_categories_attributes: params[:account_book_type][:expense_categories_attributes].permit!
        })
      end
    end
    attributes
  end

  def source
    (@organization.is_journals_management_centralized || @user.is_admin) ? @organization : @user
  end

  def load_customer
    if params[:customer_id].present?
      @customer = customers.find_by_slug! params[:customer_id]
      raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
    end
  end

  def load_journal
    @journal = (@customer || source).account_book_types.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(AccountBookType, slug: params[:id]) unless @journal
  end

  def is_max_number_reached?
    @customer.account_book_types.count >= @customer.options.max_number_of_journals
  end
  helper_method :is_max_number_reached?

  def is_preassignment_authorized?
    @customer.nil? || @customer.options.is_preassignment_authorized
  end
  helper_method :is_preassignment_authorized?

  def verify_max_number
    if @customer && is_max_number_reached?
      flash[:error] = "Nombre maximum de journaux comptables atteint : #{@customer.account_book_types.count}/#{@customer.options.max_number_of_journals}."
      redirect_to account_organization_customer_path(@organization, @customer, tab: 'journals')
    end
  end
end
