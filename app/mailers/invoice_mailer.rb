# -*- encoding : UTF-8 -*-
class InvoiceMailer < ActionMailer::Base
  def notify(invoice)
    organization = invoice.organization
    attachments[invoice.cloud_content_object.filename] = File.read(invoice.cloud_content_object.path)
    @user = organization.admins.order(:created_at).first

    if organization.invoice_mails.present?
      mail(to: @user.email, cc: organization.invoice_mails.split(',').map{ |mail| mail.strip }, subject: '[iDocus] Nouvelle facture disponible').deliver
    else
      mail(to: @user.email, subject: '[iDocus] Nouvelle facture disponible').deliver
    end
  end
end
