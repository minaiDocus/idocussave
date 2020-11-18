# frozen_string_literal: true

class Account::FtpsController < Account::AccountController
  before_action :verify_authorization
  before_action :load_ftp

  def edit; end

  def update
    @ftp.assign_attributes(ftp_params)
    if @ftp.valid? && Ftp::VerifySettings.new(@ftp, current_user.code).execute
      @ftp.is_configured = true
      @ftp.save
      flash[:success] = 'Votre compte FTP a été configuré avec succès.'
      redirect_to account_profile_path(anchor: 'ftp', panel: 'efs_management')
    else
      flash[:error] = @ftp.reload.error_message
      render :edit
    end
  end

  def destroy
    @ftp.reset_info
    flash[:success] = 'Vos paramètres FTP ont été réinitialisé.'
    redirect_to account_profile_path(anchor: 'ftp', panel: 'efs_management')
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
    params.require(:ftp).permit(:host, :port, :is_passive, :login, :password)
  end
end
