# frozen_string_literal: true

class Account::Organization::FtpsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_ftp

  def edit; end

  def update
    _params = ftp_params.delete_if { |k, _| k == 'password' }

    is_connection_params_changed = false
    is_connection_params_changed = true if @ftp.host != _params[:host]
    is_connection_params_changed = true if @ftp.port != _params[:port].to_i
    is_connection_params_changed = true if @ftp.login != _params[:login]
    if @ftp.is_passive != (_params[:is_passive] == '1')
      is_connection_params_changed = true
    end

    if ftp_params[:password].present? || is_connection_params_changed
      @ftp.assign_attributes password: ftp_params[:password]
    end

    @ftp.assign_attributes _params

    result = @ftp.valid?
    is_verified = false
    if result && @ftp.password_changed?
      result = Ftp::VerifySettings.new(@ftp, current_user.code).execute
      is_verified = true
    end
    if result
      @ftp.is_configured = true if is_verified
      @ftp.save
      flash[:success] = 'Vos paramètres FTP ont été modifiés avec succès.'
      redirect_to account_organization_path(@organization, tab: 'ftp')
    else
      flash[:error] = @ftp.reload.error_message
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
      FileImport::Ftp.delay.process @ftp.id
      flash[:notice] = 'Tentative de récupération des documents depuis votre FTP en cours.'
    else
      flash[:error] = "Votre FTP n'a pas été configuré correctement."
    end
    redirect_to account_organization_path(@organization, tab: 'ftp')
  end

  private

  def verify_rights
    unless @user.leader?
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
