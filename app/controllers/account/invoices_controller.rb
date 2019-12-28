# frozen_string_literal: true

class Account::InvoicesController < Account::OrganizationController
  def show
    @invoices = @organization.invoices.order(created_at: :desc).page(params[:page])
  end

  def download
    invoice    = Invoice.find params[:id] if params[:id].present?
    authorized = @user.leader?

    if invoice && invoice.organization == @organization && File.exist?(invoice.cloud_content_object.path) && authorized
      filename = File.basename invoice.cloud_content_object.path
      # type = invoice.content_content_type || 'application/pdf'
      # find a way to get active storage mime type
      type = 'application/pdf'
      send_file(invoice.cloud_content_object.path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end
end
