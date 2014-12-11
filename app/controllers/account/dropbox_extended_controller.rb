# -*- encoding : UTF-8 -*-
class Account::DropboxExtendedController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_session

  def authorize_url
    options = params[:user].present? ? '?user=' + params[:user] : ''
    redirect_to @session.get_authorize_url(callback_account_organization_dropbox_extended_url + options)
  end

  def callback
    @session.get_access_token
    DropboxExtended.save_session(@session)
    flash[:notice] = 'Le compte Dropbox-Extended a été configuré avec succès.'
    user = User.find_by_slug params[:user]
    if user
      if user.is_prescriber
        redirect_to account_organization_collaborator_path(user.organization, user, tab: 'file_storages')
      else
        redirect_to account_organization_customer_path(user.organization, user, tab: 'file_storages')
      end
    else
      redirect_to account_organizations_path
    end
  end

private

  def verify_rights
    unless current_user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_session
    @session = DropboxExtended.get_session
  end
end
