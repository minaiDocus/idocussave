class Account::DropboxesController < Account::AccountController
  before_filter :dropbox_authorized?
  before_filter :load_dropbox
  
private

  def dropbox_authorized?
    unless current_user.is_dropbox_authorized
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Dropbox."
      redirect_to account_profile_path
    end
  end

  def load_dropbox
    @dropbox = current_user.my_dropbox
    if @dropbox.nil?
      @dropbox = MyDropbox.create(:user_id => current_user.id)
      current_user.update_attributes(:my_dropbox_id => @dropbox.id)
    end
  end

public

  def authorize_url
    @dropbox.reset_session
    @dropbox.new_session
    redirect_to @dropbox.get_authorize_url callback_account_dropbox_url
    # render :text => @dropbox.get_authorize_url(callback_account_dropbox_url)
  end
  
  def callback
    @dropbox.get_access_token
    flash[:notice] = "Votre compte Dropbox à été configuré avec succès."
    redirect_to account_profile_path
  end
  
end
