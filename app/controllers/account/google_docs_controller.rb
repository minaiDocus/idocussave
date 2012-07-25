# -*- encoding : UTF-8 -*-
class Account::GoogleDocsController < Account::AccountController
  before_filter :service_authorized?
  before_filter :load_google_doc
  
private
  def service_authorized?
    unless current_user.external_file_storage.try("is_google_docs_authorized?")
      flash[:error] = "Vous n'êtes pas autorisé à utiliser Google Drive."
      redirect_to account_profile_path
    end
  end
  
  def load_google_doc
    current_user.external_file_storage.create unless current_user.external_file_storage
    @google_doc = current_user.external_file_storage.google_doc
    @google_doc = external_file_storage.google_doc.create unless @google_doc
  end
  
public
  def authorize_url
    @google_doc.reset_session
    redirect_to @google_doc.get_authorize_url(callback_account_google_doc_url)
  end
  
  def callback
    @google_doc.get_access_token(params[:oauth_verifier])
    flash[:notice] = "Votre compte Google Drive à été configuré avec succès."
    redirect_to account_profile_path
  end
  
end
