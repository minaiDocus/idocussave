# -*- encoding : UTF-8 -*-
class InvoiceMailer < ActionMailer::Base
  def notify(invoice)
    organization = invoice.organization
    attachments[invoice.content_file_name] = File.read(invoice.content.path)
    @user = organization.admins.order(:created_at).first

    if organization.invoice_mails.present?
      mail(to: @user.email, cc: organization.invoice_mails.split(',').map{ |mail| mail.strip }, subject: '[iDocus] Nouvelle facture disponible')
    else
      mail(to: @user.email, subject: '[iDocus] Nouvelle facture disponible')
    end
  end
end
