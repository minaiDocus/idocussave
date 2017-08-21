class Account::FtpsController < Account::AccountController
  before_action :verify_authorization
  before_action :load_ftp

  def edit
  end

  def update
    @ftp.assign_attributes(ftp_params)
    if @ftp.valid? && VerifyFtpSettings.new(@ftp, current_user.code).execute
      @ftp.is_configured = true
      @ftp.save
      flash[:success] = 'Votre compte FTP a été configuré avec succès.'
      redirect_to account_profile_path(anchor: 'ftp', panel: 'efs_management')
    else
      flash[:error] = 'Vos paramètres FTP ne sont pas valides.'
      render :edit
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

  def ftp_params
    params.require(:ftp).permit(:host, :login, :password)
  end
end
