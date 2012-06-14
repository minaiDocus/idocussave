class Account::FtpsController < Account::AccountController
  before_filter :load_ftp
  
private
  def load_ftp
    user = current_user
    user.external_file_storage.create if !user.external_file_storage
    user.external_file_storage.ftp.create if !user.external_file_storage.ftp
    @ftp = user.external_file_storage.ftp
  end
  
public
  def configure
    @ftp.host = params[:ftp][:host]
    @ftp.login = params[:ftp][:login]
    @ftp.password = params[:ftp][:password]
    is_ok = @ftp.valid?
    is_ok = @ftp.verify! if is_ok
    if is_ok
      flash[:notice] = "Configuré avec succès."
    else
      flash[:error] = "Paramètre(s) non valide."
    end
    respond_to do |format|
      format.json{ render :json => is_ok.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path }
    end
  end
  
end
