class Account::InvoicesController < Account::OrganizationController
  def show
    @invoices = @organization.invoices.order(created_at: :desc).page(params[:page])
  end

  def download
    invoice    = Invoice.find params[:id] if params[:id].present?
    authorized = @user.leader?

    if invoice && invoice.organization == @organization && File.exist?(invoice.content.path) && authorized
      filename = File.basename invoice.content.path
      type = invoice.content_content_type || 'application/pdf'
      send_file(invoice.content.path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end
end
