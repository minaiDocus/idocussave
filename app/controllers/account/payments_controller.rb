# -*- encoding : UTF-8 -*-
class Account::PaymentsController < Account::AccountController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :login_user!
  skip_before_filter :load_user_and_role
  skip_before_filter :verify_suspension

  def use_debit_mandate
    redirect_to account_profile_path(panel: 'payment_management')
  end

  def debit_mandate_notify
    attributes = DebitMandateResponseService.new(params[:blob]).execute
    if attributes.present?
      user = User.find_by_email attributes['email']
      if user
        user.debit_mandate ||= DebitMandate.new
        user.debit_mandate.assign_attributes(attributes)
        user.debit_mandate.save
        if user.debit_mandate.transactionStatus == 'success'
          user.organization.update_attribute(:is_suspended, false) if user.try(:organization).try(:is_suspended)
        end
      end
      render text: 'OK'
    else
      render text: 'Erreur'
    end
  end
end
