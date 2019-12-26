# frozen_string_literal: true

class Account::FileStorageAuthorizationsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_someone
  before_action :verify_if_someone_is_active
  before_action :load_url_path

  # GET /account/organizations/:organization_id/collaborators/:collaborator_id/file_storage_authorizations/edit
  def edit; end

  # PUT /account/organizations/:organization_id/collaborators/:collaborator_id/file_storage_authorizations
  def update
    @someone.update(user_params)
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
      external_file_storage_attributes: %i[
        id
        is_dropbox_basic_authorized
        is_google_docs_authorized
        is_ftp_authorized
        is_box_authorized
      ]
    )
  end

  def load_someone
    if params[:collaborator_id].present?
      @member = @organization.members.find params[:collaborator_id]
      @someone = @member.user
    else
      @member = nil
      @someone = @organization.customers.find params[:customer_id]
    end
  end

  def verify_if_someone_is_active
    if @someone.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_url_path
    if @someone.is_prescriber
      @put_url_path = account_organization_collaborator_file_storage_authorizations_path(@organization, @member)
      @url_path     = account_organization_collaborator_path(@organization, @member, tab: 'file_storages')
    else
      @put_url_path = account_organization_customer_file_storage_authorizations_path(@organization, @someone)
      @url_path     = account_organization_customer_path(@organization, @someone, tab: 'file_storages')
    end
  end
end
