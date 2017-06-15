# -*- encoding : UTF-8 -*-
class Account::PaymentsController < Account::AccountController
  skip_before_filter :login_user!
  skip_before_filter :verify_suspension
  skip_before_filter :load_user_and_role
  skip_before_filter :verify_authenticity_token


  # GET /account/payment/use_debit_mandate
  def use_debit_mandate
    redirect_to account_profile_path(panel: 'payment_management')
  end


  # POST /account/payment/debit_mandate_notify
  def debit_mandate_notify
    attributes = DebitMandateResponseService.new(params[:blob]).execute

    if attributes.present?
      debit_mandate = DebitMandate.where(clientReference: attributes['clientReference']).first

      if debit_mandate
        debit_mandate.update(attributes)

        if debit_mandate.configured? && debit_mandate.organization.is_suspended
          debit_mandate.organization.update(is_suspended: false)
        end

        render text: 'OK'
      else
        render text: 'Erreur'
      end
    else
      render text: 'Erreur'
    end
  end
end
