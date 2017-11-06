# -*- encoding : UTF-8 -*-
class Account::ProfilesController < Account::AccountController
  # GET /account/profile
  def show
    if @user.active?
      @external_file_storage = @user.find_or_create_external_file_storage

      if @user.my_organization
        @invoices = @user.my_organization.invoices.order(created_at: :desc).page(params[:page])
      else
        @invoices = @user.invoices.order(created_at: :desc).page(params[:page])
      end
    end

    @active_panel = params[:panel] || 'change_password'
  end

  # PUT /account/profile
  def update
    if params[:user][:current_password]
      if @user.valid_password?(params[:user][:current_password])
        @user.password =              params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]

        if @user.save
          flash[:notice] = "Votre mot de passe a été mis à jour avec succès"
        else
          flash[:alert] = "Une erreur est survenue lors de la mise à jour de votre mot de passe"
        end
      else
        flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
      end
    elsif @user.active?
      params[:user].reject! { |key, _value| key == 'password' || key == 'password_confirmation' }

      if @user.update(user_params)
        flash[:success] = "Modifié avec succès."
      else
        flash[:error] = 'Impossible de sauvegarder.'
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
    params.require(:user).permit(
      notify_attributes: [
        :id,
        :to_send_docs,
        :published_docs,
        :reception_of_emailed_docs,
        :r_site_unavailable,
        :r_action_needed,
        :r_bug,
        :r_no_bank_account_configured,
        :r_new_documents,
        :r_new_operations
      ]
    )
  end
end
