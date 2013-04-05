# -*- encoding: UTF-8 -*-
module Admin::InvoicesHelper
  def owner_invoice_link(invoice)
    if invoice.organization
      content_tag :a, invoice.organization.leader.code, href: admin_organization_path(invoice.organization)
    elsif invoice.user
      content_tag :a, invoice.user.code, href: admin_user_path(invoice.user)
    else
      ''
    end
  end
end