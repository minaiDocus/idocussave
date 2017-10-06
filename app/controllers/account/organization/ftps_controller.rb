class Account::Organization::FtpsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_ftp

  def edit
  end

  def update
    @ftp.assign_attributes(ftp_params.delete_if { |k,v| k == 'password' && v.blank? })
    result = @ftp.valid?
    is_verified = false
    if result && @ftp.password_changed?
      result = VerifyFtpSettings.new(@ftp, current_user.code).execute
      is_verified = true
    end
    if result
      @ftp.is_configured = true if is_verified
      @ftp.save
      flash[:success] = 'Vos paramètres FTP ont été modifiés avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ftp')
    else
      flash[:error] = 'Vos paramètres FTP ne sont pas valides.'
      render :edit
    end
  end

  def destroy
    @ftp.reset_info
    flash[:success] = 'Vos paramètres FTP ont été réinitialisés.'
    redirect_to account_organization_path(@organization, tab: 'ftp')
  end

  def fetch_now
    if @ftp.configured?
      ImportFromFTPWorker.perform_async @ftp.id
      flash[:notice] = 'Tentative de récupération des documents depuis votre FTP en cours.'
    else
      flash[:error] = "Votre FTP n'a pas été configuré correctement."
    end
    redirect_to account_organization_path(@organization, tab: 'ftp')
  end

  private

  def verify_rights
    unless @user.is_admin || is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_ftp
    @ftp = @organization.ftp
    @ftp ||= @organization.ftp = Ftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
  end

  def ftp_params
    params.require(:ftp).permit(:host, :port, :is_passive, :login, :password, :root_path, :path)
  end
end
