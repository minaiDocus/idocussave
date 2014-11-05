# -*- encoding : UTF-8 -*-
class Account::ProfilesController < Account::AccountController
  def show
    @external_file_storage = @user.find_or_create_external_file_storage
    if @user.my_organization
      @invoices = @user.my_organization.invoices.desc(:created_at).page(params[:page])
    else
      @invoices = @user.invoices.desc(:created_at).page(params[:page])
    end
    @active_panel = params[:panel] || 'change_password'
  end

  def update
    if params[:user][:current_password]
      if @user.valid_password?(params[:user][:current_password])
        if @user.update_attributes(user_params)
          flash[:notice] = "Votre mot de passe a été mis à jour avec succès"
        else
          flash[:alert] = "Une erreur est survenue lors de la mise à jour de votre mot de passe"
        end
      else
        flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
      end
    else
      params[:user].reject!{ |key,value| key == 'password' || key == 'password_confirmation' }
      if @user.update_attributes(user_params)
        flash[:success] = "Modifié avec succès."
      else
        flash[:error] = "Impossible de sauvegarder."
      end
    end

    if params[:panel]
      redirect_to account_profile_path(panel: params[:panel])
    else
      redirect_to account_profile_path
    end
  end

private
  def user_params
    params.require(:user).permit(:current_password,
                                 :password, :password_confirmation,
                                 :is_reminder_email_active,
                                 :is_document_notifier_active,
                                 :is_mail_receipt_activated)
  end
end
