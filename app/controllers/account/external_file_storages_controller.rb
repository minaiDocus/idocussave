# -*- encoding : UTF-8 -*-
class Account::ExternalFileStoragesController < Account::AccountController
  before_filter :load_external_file_storage

private
  def load_external_file_storage
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

  def update
    result = ""
    if params[:dropbox_basic]
      @external_file_storage.dropbox_basic.create if !@external_file_storage.dropbox_basic
      result = @external_file_storage.dropbox_basic.update dropbox_basic_params
    elsif params[:google_doc]
      @external_file_storage.google_doc.create if !@external_file_storage.google_doc
      result = @external_file_storage.google_doc.update google_doc_params
    elsif params[:ftp]
      @external_file_storage.ftp.create if !@external_file_storage.ftp
      result = @external_file_storage.ftp.update ftp_params
    elsif params[:box]
      @external_file_storage.box.create if !@external_file_storage.box
      result = @external_file_storage.box.update box_params
    end
    if result == true
      flash[:notice] = "Modifié avec succés."
    else
      flash[:error] = "Donnée(s) saisie(s) non valide."
    end
    respond_to do |format|
      format.json{ render :json => result.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path(panel: 'efs_management') }
    end
  end

  def dropbox_basic_params
    params.require(:dropbox_basic).permit(:path)
  end

  def google_doc_params
    params.require(:google_doc).permit(:path)
  end

  def ftp_params
    params.require(:ftp).permit(:path)
  end

  def box_params
    params.require(:box).permit(:path)
  end
end
