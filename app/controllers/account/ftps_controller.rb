class Account::FtpsController < Account::AccountController
  before_action :verify_authorization
  before_action :load_ftp

  def configure
    @ftp.host     = params[:ftp][:host]
    @ftp.login    = params[:ftp][:login]
    @ftp.password = params[:ftp][:password]

    if @ftp.save && @ftp.verify!
      flash[:success] = 'Votre compte FTP a été configuré avec succès.'
    else
      flash[:error] = 'Vos paramètres FTP ne sont pas valides.'
    end

    respond_to do |format|
      format.json { render json: is_ok.to_json, status: :ok }
      format.html { redirect_to account_profile_path }
    end
  end

private

  def verify_authorization
    unless @user.find_or_create_external_file_storage.is_ftp_authorized?
      flash[:error] = "Vous n'êtes pas autorisé à utiliser FTP."
      redirect_to account_profile_path(panel: 'efs_management')
    end
  end

  def load_ftp
    @ftp = @user.find_or_create_external_file_storage.ftp
  end
end
