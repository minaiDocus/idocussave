class Account::ProfilesController < Account::AccountController
  
public
  def show
    @user = current_user
    @external_file_storage = @user.find_or_create_external_file_storage
  end
  
  def update
    @user = current_user
    if @user.valid_password?(params[:user][:current_password])
      if @user.update_attributes(params[:user])
        flash[:notice] = "Votre mot de passe a été mis à jour avec succès"
      else
        flash[:alert] = "Une erreur est survenue lors de la mise à jour de votre mot de passe"
      end
    else
      flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
    end

    redirect_to account_profile_path(@user)
  end
end
