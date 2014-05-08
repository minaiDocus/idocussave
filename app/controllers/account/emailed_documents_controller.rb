# -*- encoding : UTF-8 -*-
class Account::EmailedDocumentsController < Account::AccountController
  def regenerate_code
    if @user.update_email_code
      flash[:success] = 'Code régénéré avec succès.'
    else
      flash[:error] = "Impossible d'effectuer l'opération demandée"
    end
    redirect_to account_profile_path(panel: 'emailed_documents')
  end
end
