class Account::JournalsController < Account::AccountController
  layout 'organization'

  before_filter :verify_management_access
  before_filter :load_user_and_role
  before_filter :load_organization
  before_filter :load_journal, except: %w(index new create)
  before_filter :verify_write_access, except: %w(index new create)

  def index
    @journals = @user.my_account_book_types.unscoped.asc(:name)
  end

  def new
    @journal = AccountBookType.new
  end

  def create
    @journal = AccountBookType.new journal_params
    if @journal.valid?
      @journal.clients = []
      @journal.is_new = true
      @journal.request_type = 'adding'
      @journal.save
      @user.my_account_book_types << @journal
      redirect_to account_organization_journals_path
    else
      render action: 'new'
    end
  end

  def edit
    @journal.apply_changes
  end

  def update
    respond_to do |format|
      @journal.assign_attributes journal_params
      if @journal.valid?
        if @journal.is_new
          @journal.save
        else
          @journal.request_changes!
          if @journal.is_update_requested?
            @journal.reload
            @journal.update_attribute(:request_type, 'updating') unless @journal.is_new
          else
            @journal.update_attribute(:request_type, '')
          end
        end
        format.json{ render json: @journal.to_json, status: :ok }
        format.html{ redirect_to account_organization_journals_path }
      else
        format.json{ render json: {}, status: :unprocessable_entity }
        format.html{ render action: 'edit' }
      end
    end
  end

  def update_requested_users
    @journal.update_requested_clients params[:account_book_type][:requested_client_ids]
    respond_to do |format|
      format.json{ render json: @journal.to_json, status: :ok }
      format.html{ redirect_to account_organization_journals_path }
    end
  end

  def update_is_default_status
    @journal.is_default = params[:value] == 'true' ? true : false
    @journal.save
    respond_to do |format|
      format.json { render json: {}, status: :ok }
    end
  end

  def destroy
    @journal.request_destroy
    redirect_to account_organization_journals_path
  end

  def cancel_destroy
    @journal.cancel_destroy_request
    redirect_to account_organization_journals_path
  end

private

  def journal_params
    params.require(:account_book_type).permit(:name,
                                              :description,
                                              :position,
                                              :entry_type,
                                              :account_number,
                                              :charge_account,
                                              :is_default)
  end

  def load_journal
    begin
      @journal = @user.my_account_book_types.unscoped.find(params[:id])
    rescue BSON::InvalidObjectId
      @journal = @user.my_account_book_types.unscoped.find_by_slug(params[:id])
    end
  end
end