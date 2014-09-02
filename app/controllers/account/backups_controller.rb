# -*- encoding : UTF-8 -*-
class Account::BackupsController < Account::AccountController
  def index
    @backups = current_user.backups
  end

  def update
    @backup = Backup.find params[:id]
    if @backup.update_attributes params[:backup]
      flash[:notice] = "Modifié avec succès."
      respond_to do |format|
        format.json{ render :json => {}, :status => :ok }
        format.html{ redirect_to account_backups_path }
      end
    else
      flash[:error] = "Une erreur est survenu lors de l'enregistrement de vos paramétre, veuillez réessayer plus tard."
      respond_to do |format|
        format.json{ render :json => {}, :status => :error }
        format.html{ redirect_to account_backups_path }
      end
    end
  end
end
