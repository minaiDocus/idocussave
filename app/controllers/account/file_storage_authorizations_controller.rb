# -*- encoding : UTF-8 -*-
class Account::FileStorageAuthorizationsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_someone
  before_filter :load_url_path

  def edit
  end

  def update
    @someone.update_attributes(user_params)
    flash[:success] = 'Modifié avec succès.'
    redirect_to @url_path
  end

private

  def verify_rights
    unless current_user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def user_params
    params.require(:user).permit(
      :is_dropbox_extended_authorized,
      external_file_storage_attributes: [
        :is_dropbox_basic_authorized,
        :is_google_docs_authorized,
        :is_ftp_authorized,
        :is_box_authorized
      ]
    )
  end

  def load_someone
    @someone = User.find (params[:collaborator_id] || params[:customer_id])
  end

  def load_url_path
    if @someone.is_prescriber
      @put_url_path = account_organization_collaborator_file_storage_authorizations_path(@organization, @someone)
      @url_path     = account_organization_collaborator_path(@organization, @someone, tab: 'file_storages')
    else
      @put_url_path = account_organization_customer_file_storage_authorizations_path(@organization, @someone)
      @url_path     = account_organization_customer_path(@organization, @someone, tab: 'file_storages')
    end
  end
end
