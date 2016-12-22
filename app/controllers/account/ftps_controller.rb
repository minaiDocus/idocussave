# -*- encoding : UTF-8 -*-
class Account::FtpsController < Account::AccountController
  before_filter :load_ftp


  # POST /account/ftp/configure
  def configure
    @ftp.host     = params[:ftp][:host]
    @ftp.login    = params[:ftp][:login]
    @ftp.password = params[:ftp][:password]

    if @ftp.save && @ftp.verify!
      flash[:notice] = "Configuré avec succès."
    else
      flash[:error] = "Paramètre(s) non valide."
    end

    respond_to do |format|
      format.json { render json: is_ok.to_json, status: :ok }
      format.html { redirect_to account_profile_path }
    end
  end


  private

  def load_ftp
    @user.external_file_storage.create unless @user.external_file_storage

    unless @user.external_file_storage.ftp
      @user.external_file_storage.ftp = Ftp.new

      @user.external_file_storage.ftp.save
    end

    @ftp = @user.external_file_storage.ftp
  end
end
