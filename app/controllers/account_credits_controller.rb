class AccountCreditsController < ApplicationController

  layout nil
  
  helper :paiement_cic
  
  skip_before_filter :authenticate_user!, :only => [:callback]
  skip_before_filter :verify_authenticity_token, :only => [:callback]

  def index
  	if params[:id]
    	credit = Credit.find_number params[:order_id]
      credit.set_pay
    end
    if params[:amount]
    	if Credit.where(:state => "unpaid", :user_id => current_user.id).last.amount != params[:amount].to_i
    	  @credit = Credit.create!(:amount => params[:amount], :user => current_user, :payment_type => "paypal")
      else
        @credit = Credit.last
      end
      values = {
        :business => 'lailol_1312465379_biz@directmada.com',
        :cmd => '_cart',
        :upload => 1,
        :notify_url => notify_account_paypal_url,
        :return => success_account_paypal_url(@credit.number),
        :invoice => @credit.number,
        :amount_1 => @credit.amount,
        :item_name_1 => "credit account",
        :item_number_1 => 1,
        :quantity_1 => 1
      }
      @link_to_paypal = "https://www.sandbox.paypal.com/cgi-bin/webscr?"+ values.to_query
    end
  end

  def notify
    credit = Credit.find_number params[:invoice]
    credit.params = params
    credit.set_pay
    render :nothing => true
  end

  def callback
    if PaiementCic.verify_hmac(params)
      credit = Credit.find_number params[:reference]

      credit.payment_type = 'CB'

      code_retour = params['code-retour']

      if code_retour == "Annulation"
        credit.cancel!
        credit.update_attributes :description => "Paiement refusé par la banque."

      elsif code_retour == "payetest"
        credit.set_pay
        credit.update_attributes :description => "TEST accepté par la banque."
        credit.update_attributes :test => true

      elsif code_retour == "paiement"
        credit.set_pay
        credit.update_attributes :description => "Paiement accepté par la banque."
        credit.update_attributes :test => false
      end

      receipt = "OK"
    else
      credit.payment_type = 'CB'
      credit.update_attributes :description => "Document Falsifie."

      receipt = "Document Falsifie"
    end
    render :text => "Version: 1\n#{receipt}\n"
  end

  def success
    render :action => :index
  end

  def cancel
    render :action => :index
  end
  
end