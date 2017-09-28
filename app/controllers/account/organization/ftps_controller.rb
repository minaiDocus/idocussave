class Account::Organization::FtpsController < Account::OrganizationController
  before_action :load_ftp

  def edit
  end

  def update
    @ftp.assign_attributes(ftp_params)
    if @ftp.valid? && VerifyFtpSettings.new(@ftp, current_user.code).execute
      @ftp.is_configured = true
      @ftp.save
      flash[:success] = 'Votre compte FTP a été configuré avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ftp')
    else
      flash[:error] = 'Vos paramètres FTP ne sont pas valides.'
      render :edit
    end
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

  def load_ftp
    @ftp = @organization.ftp
    @ftp ||= @organization.ftp = Ftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
  end

  def ftp_params
    params.require(:ftp).permit(:host, :port, :is_passive, :login, :password)
  end
end
