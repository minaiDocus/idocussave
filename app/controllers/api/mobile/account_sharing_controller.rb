# -*- encoding : UTF-8 -*-
class Api::Mobile::AccountSharingController < MobileApiController
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  before_filter :load_organization

  respond_to :json

  def load_shared_docs
    account_sharings = AccountSharing.unscoped.where(account_id: customers).search(search_terms(params[:account_sharing_contains])).
      page(1).
      per(100)

    data_docs = account_sharings.inject([]) do |memo, data|
      memo += [ {
                  id_idocus:data.id,
                  date:data.created_at, 
                  approval:data.is_approved,
                  client:data.collaborator.info,
                  document:data.account.info
                },
              ]
    end
    render json: {data_shared: data_docs}, status: 200
  end

  def get_list_collaborators
    collaborators = @organization.customers

    collaborators_options = collaborators.inject([]) do |memo, collab|
      memo += [
                value: collab.id,
                label: "#{collab.code} - #{collab.company}"
              ]
    end

    render json: {options: collaborators_options}, status: 200
  end

  def add_shared_docs
    account_sharing = ShareAccount.new(@user, account_sharing_params, current_user).execute
    if account_sharing.persisted?
      render json: {message: 'Dossier partagé avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de créer le partage.'}, status: 200
    end
  end

  def accept_shared_docs
    account_sharing = AccountSharing.unscoped.where(account_id: customers).find params[:id]
    if(AcceptAccountSharingRequest.new(account_sharing).execute)
      render json: {message: 'Le partage a été valider avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de valider le partage.'}, status: 200
    end
  end

  def delete_shared_docs 
    account_sharing = AccountSharing.unscoped.where(account_id: customers).find params[:id]
    if DestroyAccountSharing.new(account_sharing).execute
      render json: {message: 'Le partage a été supprimer avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de supprimer le partage.'}, status: 200
    end
  end


  private

  def account_sharing_params
    params.require(:account_sharing).permit(:collaborator_id, :account_id)
  end

end