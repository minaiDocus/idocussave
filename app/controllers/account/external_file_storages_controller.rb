# frozen_string_literal: true

class Account::ExternalFileStoragesController < Account::AccountController
  before_action :load_external_file_storage

  def use
    service   = params[:service].to_i
    is_enable = params[:is_enable] == 'true'

    response = if is_enable
                 @external_file_storage.use(service)
               else
                 @external_file_storage.unuse(service)
               end

    respond_to do |format|
      format.json { render json: response.to_json, status: :ok }
      format.html { redirect_to account_profile_path }
    end
  end

  def update
    service_name = %i[dropbox_basic google_doc ftp box].select do |key|
      params[key].present?
    end.first

    if service_name && @external_file_storage.send(service_name).update(path: params[service_name][:path])
      flash[:success] = 'Modifié avec succés.'
    else
      flash[:error] = 'Donnée(s) saisie(s) non valide.'
    end

    respond_to do |format|
      format.json { render json: result.to_json, status: :ok }
      format.html { redirect_to account_profile_path(panel: 'efs_management', anchor: anchor_name(service_name)) }
    end
  end

  private

  def load_external_file_storage
    @external_file_storage = @user.find_or_create_external_file_storage
  end

  def anchor_name(service_name)
    case service_name
    when :dropbox_basic
      :dropbox
    when :google_doc
      :google_drive
    else
      service_name
    end
  end
end
