# frozen_string_literal: true

class Account::Organization::SftpsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_sftp

  def edit; end

  def update
    _params = sftp_params.delete_if { |k, _| k == 'password' }

    is_connection_params_changed = false
    is_connection_params_changed = true if @sftp.host != _params[:host]
    is_connection_params_changed = true if @sftp.port != _params[:port].to_i
    is_connection_params_changed = true if @sftp.login != _params[:login]

    if sftp_params[:password].present? || is_connection_params_changed
      @sftp.assign_attributes password: sftp_params[:password]
    end

    @sftp.assign_attributes _params

    result = @sftp.valid?
    is_verified = false
    if result && @sftp.password_changed?
      result = Sftp::VerifySettings.new(@sftp, current_user.code).execute
      is_verified = true
    end
    if result
      @sftp.is_configured = true if is_verified
      @sftp.save
      flash[:success] = 'Vos paramètres SFTP ont été modifiés avec succès.'
      redirect_to account_organization_path(@organization, tab: 'sftp')
    else
      flash[:error] = @sftp.reload.error_message
      render :edit
    end
  end

  def destroy
    @sftp.reset_info
    flash[:success] = 'Vos paramètres SFTP ont été réinitialisés.'
    redirect_to account_organization_path(@organization, tab: 'sftp')
  end

  def fetch_now
    if @sftp.configured?
      FileImport::Sftp.delay.process @sftp.id
      flash[:notice] = 'Tentative de récupération des documents depuis votre SFTP en cours.'
    else
      flash[:error] = "Votre SFTP n'a pas été configuré correctement."
    end
    redirect_to account_organization_path(@organization, tab: 'sftp')
  end

  private

  def verify_rights
    unless @user.leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_sftp
    @sftp = @organization.sftp
    @sftp ||= @organization.sftp = Sftp.create(organization: @organization, path: 'OUTPUT/:code/:year:month/:account_book/')
  end

  def sftp_params
    params.require(:sftp).permit(:host, :port, :login, :password, :root_path, :path)
  end
end
