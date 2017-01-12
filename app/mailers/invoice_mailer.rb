# -*- encoding : UTF-8 -*-
class InvoiceMailer < ActionMailer::Base
  def notify(invoice)
    @user = invoice.user
    
    attachments[invoice.content_file_name] = File.read(invoice.content.path)

    mail(to: @user.email, subject: '[iDocus] Nouvelle facture disponible')
  end
end
