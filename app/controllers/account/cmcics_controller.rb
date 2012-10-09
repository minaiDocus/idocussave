# -*- encoding : UTF-8 -*-
class Account::CmcicsController < Account::AccountController
  
  skip_before_filter :authenticate_user!, :only => [:callback]
  skip_before_filter :verify_authenticity_token, :only => [:callback]
  skip_before_filter :find_last_composition

  def callback
    if PaiementCic.verify_hmac(params)
      credit = Credit.find_number params[:reference]

      credit.update_attributes :payment_type => 'CB'

      code_retour = params['code-retour']

      if code_retour == "Annulation"
        unless credit.paid? || credit.credited?
          credit.cancel!
        end
        credit.update_attributes :description => "Paiement refusé par la banque."

      elsif code_retour == "payetest"
        unless credit.paid? || credit.credited?
          credit.set_pay
        end
        credit.update_attributes :description => "TEST accepté par la banque."
        credit.update_attributes :test => true

      elsif code_retour == "paiement"
        unless credit.paid? || credit.credited?
          credit.set_pay
        end
        credit.update_attributes :description => "Paiement accepté par la banque."
        credit.update_attributes :test => false
      end

      receipt = "OK"
    else
      credit.update_attributes :payment_type => 'CB'
      credit.update_attributes :description => "Document Falsifie."

      receipt = "Document Falsifie"
    end
    render :text => "Version: 1\n#{receipt}\n"
  end

  def success
    credit = Credit.find_number params[:order_id]
    flash[:notice] = "#{format_price credit.amount} € ont été ajouter avec succes à votre compte." rescue "Aucune donnée reçu."
    redirect_to account_profile_url
  end

  def cancel
    flash[:alert] = "Crédit annulé."
    redirect_to account_profile_url
  end
  
end
