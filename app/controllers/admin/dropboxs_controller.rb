# -*- encoding : UTF-8 -*-
class Admin::DropboxsController < Admin::AdminController

  before_filter :load_user, :only => %w(edit update)
  before_filter :filtered_user_ids, :only => %w(index)
  before_filter :load_dropbox, :only => %w(authorize_url callback)

protected

  def load_user
    @user = User.find params[:id]
  end
  
  def load_dropbox
    @session = DropboxExtended.get_session
  end

public

  def index
    @users = User.prescribers.dropbox_extended_authorized
    @users = @users.any_in(:_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    @users = @users.desc(:created_at).paginate :page => params[:page], :per_page => 50
  end
  
  def edit
  end
  
  def update
    if @user.update_attributes params[:user]
      flash[:notice] = "Modifiée avec succès."
      redirect_to admin_dropboxs_path
    else
      flash[:error] = "Erreur lors de la modification."
      render :action => "edit"
    end
  end
  
  def authorize_url
    redirect_to @session.get_authorize_url callback_admin_dropboxs_url
  end
  
  def callback
    @session.get_access_token
    DropboxExtended.save_session(@session)
    flash[:notice] = "Le compte Dropbox-Extended à été configuré avec succès."
    redirect_to admin_dropboxs_path
  end
  
end
