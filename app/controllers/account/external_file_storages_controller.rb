# -*- encoding : UTF-8 -*-
class Account::ExternalFileStoragesController < Account::AccountController
  
  before_filter :load_external_file_storage
  
private
  def load_external_file_storage
    @user = current_user
    @user.external_file_storage.create if !@user.external_file_storage
    @external_file_storage = @user.external_file_storage
  end
  
public
  def use
    service = params[:service].to_i
    is_enable = params[:is_enable] == "true"
    if is_enable
      response = @external_file_storage.use(service)
    else
      response = @external_file_storage.unuse(service)
    end
    respond_to do |format|
      format.json{ render :json => response.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path }
    end
  end
  
  def update_path_settings
    result = ""
    result = @external_file_storage.update_attributes(params[:external_file_storage])
    if params[:external_file_storage][:dropbox_basic]
      @external_file_storage.dropbox_basic.create if !@external_file_storage.dropbox_basic
      result = @external_file_storage.dropbox_basic.update_attributes(params[:external_file_storage][:dropbox_basic])
    elsif params[:external_file_storage][:google_doc]
      @external_file_storage.google_doc.create if !@external_file_storage.google_doc
      result = @external_file_storage.google_doc.update_attributes(params[:external_file_storage][:google_doc])
    elsif params[:external_file_storage][:ftp]
      @external_file_storage.ftp.create if !@external_file_storage.ftp
      result = @external_file_storage.ftp.update_attributes(params[:external_file_storage][:ftp])
    elsif params[:external_file_storage][:the_box]
      @external_file_storage.the_box.create if !@external_file_storage.the_box
      result = @external_file_storage.the_box.update_attributes(params[:external_file_storage][:the_box])
    end
    if result == true
      flash[:notice] = "Modifié avec succés."
    else
      flash[:error] = "Chemin non valide."
    end
    respond_to do |format|
      format.json{ render :json => result.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path(panel: 'efs_management') }
    end
  end
  
end
