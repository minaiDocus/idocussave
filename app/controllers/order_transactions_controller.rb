class OrderTransactionsController < ApplicationController

  protect_from_forgery :except => [:bank_callback]

  def bank_callback
    if PaiementCic.verify_hmac(params)
      order_transaction = OrderTransaction.find_by_reference params[:reference]
      order = order_transaction.order

      code_retour = params['code-retour']

      if code_retour == "Annulation"
        order.cancel!
        order_transaction.update_attribute :description, "Paiement refusé par la banque."

      elsif code_retour == "payetest"
        order.pay!
        order_transaction.update_attribute :description, "TEST accepté par la banque."
        order_transaction.update_attribute :test, true

      elsif code_retour == "paiement"
        order.pay!
        order_transaction.update_attribute :description, "Paiement accepté par la banque."
        order_transaction.update_attribute :test, false
      end

      order_transaction.update_attribute :success, true

      receipt = "OK"
    else
      order.transaction_decline!
      order_transaction.update_attribute :description, "Document Falsifie."
      order_transaction.update_attribute :success, false

      receipt = "Document Falsifie"
    end
    render :text => "Version: 1\n#{receipt}\n"
  end

  def bank_ok
    @order_transaction = OrderTransaction.find params[:id]
    @order = @order_transaction.order
    @order.pay!
  end

  def bank_err
    order_transaction = OrderTransaction.find params[:id]
    order = order_transaction.order
    order.cancel!
  end
end

