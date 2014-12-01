# -*- encoding : UTF-8 -*-
class Account::EmailedDocumentsController < Account::AccountController
  before_filter :verify_rights

  def regenerate_code
    if @user.update_email_code
      flash[:success] = 'Code régénéré avec succès.'
    else
      flash[:error] = "Impossible d'effectuer l'opération demandée"
    end
    redirect_to account_profile_path(panel: 'emailed_documents')
  end

private

  def verify_rights
    if @user.is_prescriber || @user.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_documents_path
    end
  end
end
