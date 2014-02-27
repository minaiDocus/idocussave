class Account::JournalsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_journal, except: %w(index new create)

  def index
    @journals = @organization.account_book_types.unscoped.asc(:name)
  end

  def new
    @journal = AccountBookType.new
  end

  def create
    @journal = AccountBookType.new journal_params
    if @journal.valid?
      @journal.save
      @journal.request.update_attributes(action: 'create', requester_id: @user.id)
      @organization.account_book_types << @journal
      redirect_to account_organization_journals_path
    else
      render action: 'new'
    end
  end

  def edit
    @journal.request.apply_attribute_changes
  end

  def update
    respond_to do |format|
      result = true
      if (attrs = expense_categories_params).present?
        result = @journal.update_attributes(attrs)
      end
      if result && @journal.request.set_attributes(journal_params, {}, @user)
        format.json{ render json: @journal.to_json, status: :ok }
        format.html{ redirect_to account_organization_journals_path }
      else
        format.json{ render json: {}, status: :unprocessable_entity }
        format.html{ render action: 'edit' }
      end
    end
  end

  def update_requested_users
    attributes = journal_relation_params
    attributes['requested_client_ids'] = [] if attributes['requested_client_ids'] == 'empty'
    old_requested_clients = @journal.requested_clients
    new_requested_clients = @user.customers.select do |e|
      if attributes['requested_client_ids'].include?(e.id.to_s)
        @journal.requested_clients.include?(e) ? true : e.is_editable
      else
        false
      end
    end
    added_clients = new_requested_clients - old_requested_clients
    removed_clients = old_requested_clients - new_requested_clients
    @journal.requested_clients = new_requested_clients
        respond_to do |format|
      if @journal.save
        modified_users = (added_clients + removed_clients).map { |e| e.reload }
        @journal.update_request_status!(modified_users)
        @journal.request.update_attribute(:requester_id, @user.id)
        format.json{ render json: @journal.to_json, status: :ok }
        format.html{ redirect_to account_organization_journals_path }
      else
        format.json{ render json: {}, status: :unprocessable_entity }
        format.html{ redirect_to account_organization_journals_path }
      end
    end
  end

  def destroy
    if @journal.request.status == 'create'
      @journal.destroy
    else
      @journal.request.update_attributes(action: 'destroy', requester_id: @user.id)
    end
    redirect_to account_organization_journals_path
  end

  def cancel_destroy
    @journal.request.update_attribute(:action, '')
    redirect_to account_organization_journals_path
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_journals?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def journal_params
    params.require(:account_book_type).permit(:name,
                                              :pseudonym,
                                              :description,
                                              :position,
                                              :entry_type,
                                              :default_account_number,
                                              :account_number,
                                              :default_charge_account,
                                              :charge_account,
                                              :vat_account,
                                              :anomaly_account,
                                              :instructions,
                                              :is_default,
                                              :client_ids)
  end

  def expense_categories_params
    if @journal.persisted? && @journal.request.action != 'create' && @journal.is_expense_categories_editable
      params.require(:account_book_type).permit(:expense_categories_attributes)
    else
      {}
    end
  end

  def journal_relation_params
    params.require(:account_book_type).permit(:requested_client_ids)
  end

  def load_journal
    begin
      @journal = @organization.account_book_types.unscoped.find(params[:id])
    rescue BSON::InvalidObjectId
      @journal = @organization.account_book_types.unscoped.find_by_slug(params[:id])
    end
  end
end