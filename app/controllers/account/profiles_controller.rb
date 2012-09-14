# -*- encoding : UTF-8 -*-
class Account::ProfilesController < Account::AccountController
  before_filter :load_user

private
  def load_user
    @user = current_user
  end
  
public
  def show
    @external_file_storage = @user.find_or_create_external_file_storage
  end
  
  def update
    if @user.valid_password?(params[:user][:current_password])
      if @user.update_attributes(params[:user])
        flash[:notice] = "Votre mot de passe a été mis à jour avec succès"
      else
        flash[:alert] = "Une erreur est survenue lors de la mise à jour de votre mot de passe"
      end
    else
      flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
    end

    redirect_to account_profile_path
  end

  def share_documents_with
    other = User.where(email: params[:email]).first
    if other
      if other != @user
        if !other.in?(@user.share_with)
          if other != @user.prescriber
            @user.share_with << other
            if @user.save && other.save
              flash[:notice] = "Vous avez paramétré le partage automatique de vos documents avec #{other.email}."
            else
              flash[:error] = "Impossible de partager vos documents."
            end
          else
            flash[:error] = "Utilisateur non valide : #{other.email}"
          end
        else
          flash[:error] = "Vos documents sont déjà partagés avec #{other.email}."
        end
      else
        flash[:error] = "Vos ne pouvez pas vous partager à vous-même."
      end
    else
      flash[:error] = "Utilisateur non trouvé : #{params[:email]}"
    end
    redirect_to account_profile_path
  end

  def unshare_documents_with
    other = User.where(email: params[:email]).first
    if other && other != @user.prescriber && other.in?(@user.share_with)
      @user.share_with -= [other]
      if @user.save && other.save
        flash[:notice] = "Vous avez supprimé le partage automatique de vos documents avec #{other.email}."
      else
        flash[:error] = "Impossible de supprimer le partage automatique de vos documents avec #{other.email}."
      end
    else
      flash[:error] = "Utilisateur non valide : #{params[:email]}"
    end
    redirect_to account_profile_path
  end
end
