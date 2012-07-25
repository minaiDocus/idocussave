# -*- encoding : UTF-8 -*-
class OrderMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"

  def payment_confirmation order
    subject       "iDocus - confirmation de votre commande"
    recipients     order.user.email

    @order = order
    mail(:to => recipients, :subject => subject)
  end

  def scanned_confirmation order
    subject       "iDocus - livraison de votre commande"
    recipients     order.user.email

    @order = order
    mail(:to => recipients, :subject => subject)
  end

end
