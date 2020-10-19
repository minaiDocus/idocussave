# frozen_string_literal: true

class Account::ProfilesController < Account::AccountController
  # GET /account/profile
  def show
    if @user.active?
      @external_file_storage = @user.find_or_create_external_file_storage

      if @external_file_storage.is_dropbox_basic_authorized?
        if @external_file_storage.dropbox_basic.access_token
          client = FileImport::Dropbox::Client.new(DropboxApi::Client.new(@external_file_storage.dropbox_basic.access_token))
          begin
            @dropbox_account = client.get_current_account
          rescue StandardError
            @dropbox_account = nil
          end
        end
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
          flash[:notice] = 'Votre mot de passe a été mis à jour avec succès'
        else
          flash[:alert] = 'Une erreur est survenue lors de la mise à jour de votre mot de passe'
        end
      else
        flash[:alert] = "Votre ancien mot de passe n'a pas été saisi correctement"
      end
    elsif @user.active?
      params[:user].reject! { |key, _value| key == 'password' || key == 'password_confirmation' }

      if @user.update(user_params)
        flash[:success] = 'Modifié avec succès.'
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
      notify_attributes: %i[
        id
        to_send_docs
        published_docs
        reception_of_emailed_docs
        r_wrong_pass
        r_site_unavailable
        r_action_needed
        r_bug
        r_no_bank_account_configured
        r_new_documents
        r_new_operations
        document_being_processed
        paper_quota_reached
        new_pre_assignment_available
        dropbox_invalid_access_token
        dropbox_insufficient_space
        ftp_auth_failure
        detected_preseizure_duplication
        pre_assignment_ignored_piece
        new_scanned_documents
        pre_assignment_delivery_errors
        mcf_document_errors
        pre_assignment_export
      ]
    )
  end
end
