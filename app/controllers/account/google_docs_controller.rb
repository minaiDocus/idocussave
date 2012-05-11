class Account::GoogleDocsController < Account::AccountController
  before_filter :service_authorized?
  before_filter :load_service
  
private

  def service_authorized?
    unless current_user.external_file_storage.try("is_google_docs_authorized?")
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Google Docs."
      redirect_to account_profile_path
    end
  end

  def load_service
    unless current_user.external_file_storage
      current_user.external_file_storage = ExternalFileStorage.create
    end
    external_file_storage = current_user.external_file_storage
    
    @service ||= external_file_storage.google_doc
    unless @service
      @service = GoogleDoc.new
      external_file_storage.google_doc = @service
      @service.save
    end
  end

public

  def authorize_url
    @service.reset_session
    redirect_to @service.get_authorize_url callback_account_google_doc_url
  end
  
  def callback
    @service.get_access_token params[:oauth_verifier]
    flash[:notice] = "Votre compte Google Docs à été configuré avec succès."
    redirect_to account_profile_path
  end
  
end
