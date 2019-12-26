# frozen_string_literal: true

class Account::UsersController < Account::AccountController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.valid_password?(params[:user][:current_password])
      if @user.update(user_params)
        flash[:notice] = 'Votre mot de passe a été mis à jour avec succès'
      else
        flash[:alert] = 'Une erreur est survenue lors de la mise à jour de votre mot de passe'
      end
    else
      flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
    end

    redirect_to edit_account_user_path(@user)
  end

  private

  def user_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
