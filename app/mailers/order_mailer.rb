# -*- encoding : UTF-8 -*-
class OrderMailer < ActionMailer::Base
  def notify_dematbox_order(order)
    @order     = order
    @address = order.address

    addresses = Array(Settings.first.notify_dematbox_order_to)

    to = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: "Commande de Demat'box")
  end


  def notify_paper_set_order(order)
    @order = order

    addresses = Array(Settings.first.notify_paper_set_order_to)

    to  = addresses.first
    cc = addresses[1..-1] || []

    mail(to: to, cc: cc, subject: 'Commande de Kit envoi courrier')
  end

  def notify_paper_set_reminder(order)
    @order = order
    to  = order.organization.leader.email
    mail(to: to, subject: 'Rappel Commande de Kit envoi courrier')
  end
end
