# frozen_string_literal: true

class Account::EmailedDocumentsController < Account::AccountController
  before_action :verify_rights

  # POST /account/emailed_documents/regenerate_code
  def regenerate_code
    if params[:customer].present?
      customer = User.find Base64.decode64(params[:customer])
      if customer && customer.options.try(:is_upload_authorized) && customer.active? && customer.update_email_code
        flash[:success] = 'Code régénéré avec succès.'
      else
        flash[:error] = "Impossible d'effectuer l'opération demandée"
      end

      redirect_to upload_email_infos_account_organization_customer_path(customer.organization, customer)
    else
      if !(@user.is_admin || @user.is_prescriber || @user.inactive?) && @user.update_email_code
        flash[:success] = 'Code régénéré avec succès.'
      else
        flash[:error] = "Impossible d'effectuer l'opération demandée"
      end

      redirect_to account_profile_path(panel: 'emailed_documents')
    end
  end

  private

  def verify_rights
    if !params[:customer].present? && (@user.is_prescriber || @user.inactive?)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end
end
