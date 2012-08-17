# -*- encoding : UTF-8 -*-
class Admin::DropboxesController < Admin::AdminController
  before_filter :load_dropbox

  protected

  def load_dropbox
    @session = DropboxExtended.get_session
  end

  public

  def authorize_url
    options = params[:user_id].present? ? '?user_id=' + params[:user_id] : ''
    redirect_to @session.get_authorize_url(callback_admin_dropbox_url + options)
  end

  def callback
    @session.get_access_token
    DropboxExtended.save_session(@session)
    flash[:notice] = "Le compte Dropbox-Extended à été configuré avec succès."
    if params[:user_id]
      user = User.find(params[:user_id])
      redirect_to admin_user_path(user)
    else
      redirect_to admin_users_path
    end
  end

end
