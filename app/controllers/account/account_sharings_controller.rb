class Account::AccountSharingsController < Account::OrganizationController
  def index
    @account_sharings = AccountSharing.where(account_id: customers).search(search_terms(params[:account_sharing_contains])).
      order(sort_column => sort_direction).
      page(params[:page]).
      per(params[:per_page])
    @account_sharing_groups = []
    @guest_collaborators = @organization.guest_collaborators
  end

  def new
    @account_sharing = AccountSharing.new
  end

  def create
    @account_sharing = AccountSharing.new account_sharing_params
    @account_sharing.organization  = @organization
    @account_sharing.requested_by  = current_user
    @account_sharing.authorized_by = current_user
    if @account_sharing.save
      DropboxImport.changed([@account_sharing.collaborator])
      flash[:success] = 'Dossier partagé avec succès.'
      redirect_to account_organization_account_sharings_path(@organization)
    else
      render :new
    end
  end

  def destroy
    @account_sharing = AccountSharing.where(account_id: customers).find params[:id]
    @account_sharing.destroy
    DropboxImport.changed([@account_sharing.collaborator])
    flash[:success] = "Partage du dossier \"#{@account_sharing.account.info}\" au collaborateur \"#{@account_sharing.collaborator.info}\" supprimé."
    redirect_to account_organization_account_sharings_path(@organization)
  end

private

  def account_sharing_params
    params.require(:account_sharing).permit(:collaborator_id, :account_id)
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
