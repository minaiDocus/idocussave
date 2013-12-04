# -*- encoding : UTF-8 -*-
class Account::PaymentsController < Account::AccountController
  skip_before_filter :verify_authenticity_token, :only => [:mode]
  
  layout nil, :only => [:credit]
  
  helper :paiement_cic
  
public
  def mode
    response = 0
    if params[:mode]
      if params[:mode] == "1"
        @user.use_debit_mandate = false
        @user.save
        response = 1
      elsif params[:mode] == "2" && @user.debit_mandate != nil
        if @user.debit_mandate.transactionStatus == "success"
          @user.use_debit_mandate = true
          @user.save
          response = 2
        else
          response = 3
        end
      else
        response = 3
      end
    end
    
    respond_to do |format|
      format.json{ render :json => response.to_json, :status => :ok }
      format.html{ redirect_to account_profile_path }
    end
  end

  def use_debit_mandate
    if @user.debit_mandate && @user.debit_mandate.transactionStatus == "success"
      @user.update_attribute(:use_debit_mandate, true)
    end
    redirect_to account_profile_path(panel: "payment_management")
  end
  
  def credit
    if params[:amount]
      amount = params[:amount].to_f * 100
      ok = Credit.where(:state => "unpaid", :user_id => @user.id).last.amount != amount rescue true
    	if ok
    	  @credit = Credit.create!(:amount => amount, :user => @user)
      else
        @credit = Credit.last
      end
      if params[:paypal]
        values = {
          :cmd => '_cart',
          :upload => 1,
          :notify_url => "#{notify_account_paypal_url}?order_id=#{@credit.number}",
          :return => "#{success_account_paypal_url}?order_id=#{@credit.number}",
          :cancel_return => "#{cancel_account_paypal_url}?order_id=#{@credit.number}",
          :invoice => @credit.number,
          :amount_1 => amount/100,
          :currency_code => 'EUR',
          :item_name_1 => "Crédit",
          :item_number_1 => 1,
          :quantity_1 => 1
        }
        if Rails.env.production?
          values = values.merge(:business => 'florent.tachot@grevalis.com');
          @link = "https://www.paypal.com/cgi-bin/webscr?"+ values.to_query
        else
          values = values.merge(:business => 'lailol_1312465379_biz@directmada.com');
          @link = "https://www.sandbox.paypal.com/cgi-bin/webscr?"+ values.to_query
        end
      elsif params[:cmcic]
        if Rails.env.production?
          @link ="https://ssl.paiement.cic-banques.fr/paiement.cgi"
        else
          @link ="https://ssl.paiement.cic-banques.fr/test/paiement.cgi"
        end
      else
        redirect_to account_profile_path
      end
    else
      redirect_to account_profile_path
    end
  end
end
