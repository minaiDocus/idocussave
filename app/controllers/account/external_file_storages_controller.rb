class Account::ExternalFileStoragesController < Account::AccountController
  
public
  def use
    @user = current_user
    @user.external_file_storage ||= ExternalFileStorage.new
    service = params[:service].to_i
    is_enable = params[:is_enable] == "true"
    if is_enable
      response = @user.external_file_storage.use service
    else
      response = @user.external_file_storage.unuse service
    end
    respond_to do |format|
      format.json{ render :json => response.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path }
    end
  end
  
end
