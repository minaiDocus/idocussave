# -*- encoding : UTF-8 -*-
class Account::PaypalsController < Account::AccountController

  skip_before_filter :authenticate_user!, :only => [:notify]
  skip_before_filter :verify_authenticity_token

  def notify
    wrap = PaypalWrapper.new(request)

    credit = Credit.find_number wrap.invoice
    credit.params = wrap.paypal_notify.params
    wrap.gross = credit.amount
    if wrap.valid?
      unless credit.paid? || credit.credited?
        credit.set_pay
      end
    end

    render :nothing => true
  end

  def success
    credit = Credit.find_number params[:order_id]
    unless credit.paid? || credit.credited?
      credit.set_pay
    end
    redirect_to account_profile_url
  end

  def cancel
    credit = Credit.find_number params[:order_id]
    unless credit.paid? || credit.credited?
      credit.cancel!
    end
    redirect_to account_profile_url
  end
end
