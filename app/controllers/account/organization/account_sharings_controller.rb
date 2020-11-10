# frozen_string_literal: true

class Account::Organization::AccountSharingsController < Account::OrganizationController
  before_action :load_account_sharing, only: %i[accept destroy]

  def index
    @account_sharings = AccountSharing.unscoped.where(account_id: customers).search(search_terms(params[:account_sharing_contains]))
                                      .order(sort_column => sort_direction)
                                      .page(params[:page])
                                      .per(params[:per_page])
    @account_sharing_groups = []
    @guest_collaborators = @organization.guest_collaborators
  end

  def new
    @account_sharing = AccountSharing.new
  end

  def create
    @account_sharing = AccountSharing::ShareAccount.new(@user, account_sharing_params, current_user).execute
    if @account_sharing.persisted?
      flash[:success] = 'Dossier partagé avec succès.'
      redirect_to account_organization_account_sharings_path(@organization)
    else
      render :new
    end
  end

  def accept
    AccountSharing::AcceptRequest.new(@account_sharing).execute
    flash[:success] = "Le dossier \"#{@account_sharing.account.info}\" a été partagé au contact \"#{@account_sharing.collaborator.info}\" avec succès."
    redirect_to account_organization_account_sharings_path(@organization)
  end

  def destroy
    AccountSharing::Destroy.new(@account_sharing).execute
    flash[:success] = "Partage du dossier \"#{@account_sharing.account.info}\" au contact \"#{@account_sharing.collaborator.info}\" supprimé."
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

  def load_account_sharing
    @account_sharing = AccountSharing.unscoped.where(account_id: customers).find params[:id]
  end
end
