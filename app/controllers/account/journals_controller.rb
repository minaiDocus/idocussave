class Account::JournalsController < Account::AccountController
  before_filter :verify_management_access
  before_filter :load_user
  before_filter :load_journal, only: %w(edit update destroy cancel_destroy edit_requested_users update_requested_users)
  before_filter :verify_write_access, only: %w(edit update destroy cancel_destroy edit_requested_users update_requested_users)

  private

  def load_journal
    @journal = @user.my_account_book_types.unscoped.find_by_slug(params[:id])
  end

  public

  def index
    @journals = @user.my_account_book_types.unscoped.asc(:name)
  end

  def new
    @journal = AccountBookType.new
  end

  def create
    @journal = AccountBookType.new params[:account_book_type]
    if @journal.valid?
      @journal.clients = []
      @journal.is_new = true
      @journal.request_type = 'adding'
      @journal.save
      @user.my_account_book_types << @journal
      @user.save
      redirect_to account_account_book_types_path
    else
      render action: 'new'
    end
  end

  def edit
    @journal.apply_changes
  end

  def update
    @journal.assign_attributes params[:account_book_type]
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
      @user.set_request_type!
      redirect_to account_account_book_types_path
    else
      render action: 'edit'
    end
  end

  def edit_requested_users
  end

  def update_requested_users
    user_ids = params[:account_book_type][:requested_client_ids].delete_if{ |e| e.blank? }
    users = @user.clients.find user_ids
    @journal.requested_clients = []
    users.each do |user|
      @journal.requested_clients << user
    end
    @journal.update_attribute(:request_type, 'updating') unless @journal.is_new
    @user.set_request_type!
    redirect_to account_account_book_types_path
  end

  def destroy
    @journal.request_destroy
    @user.set_request_type!
    redirect_to account_account_book_types_path
  end

  def cancel_destroy
    @journal.cancel_destroy_request
    @user.set_request_type!
    redirect_to account_account_book_types_path
  end
end